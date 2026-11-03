/*
 * vcat_plugin_vvdec.c -- implements the VCAT decoder plugin C ABI (vcat_decoder_plugin.h) over
 * vvdec. Built into the iOS plugin's dynamic library by ios/build_xcframework.sh; the Android
 * build goes through app/src/main/cpp/vvdec_jni.cc.
 *
 * Contains no plugin name. The identity comes from plugin.json through vcat_plugin_manifest.h,
 * which the build generates (VCAT_PLUGIN_ID, VCAT_PLUGIN_MIME, VCAT_DECODER_NAME_PREFIX, and the
 * manifest JSON in the __TEXT,__vcat_manifest section).
 *
 * Decode-loop behavior, kept identical to vvdec_jni.cc (and to the in-app Swift decoder this
 * replaces in vcat-d-ios):
 *   - vvdec_decode is a combined send+receive call. VVDEC_OK and VVDEC_TRY_AGAIN both mean the
 *     access unit was CONSUMED; TRY_AGAIN only means no picture is ready yet. Never re-send an AU
 *     on TRY_AGAIN: re-sending the opening keyframe decoded it once per TRY_AGAIN, each copy
 *     emerging as its own picture (vcatd-vvdec-plugin 1d19fd8; the reference CLI vvdecapp.cpp
 *     always advances).
 *   - Input is never refused (an old input cap ended runs mid-stall, 4b7ea71).
 *   - An access unit vvdec rejects is dropped and decoding continues; one bad packet must not
 *     end a clip.
 *   - Mid-stream there is no way to poll for pictures: a NULL AU is vvdec's flush/EOF signal, and
 *     calling it mid-stream returns VVDEC_ERR_DEC_INPUT. Pictures arrive on the back of the next
 *     AU; vvdec_flush is used only after end_of_stream.
 *   - pts is passed through as vvdec's cts and read back from each frame: VVC reorders, so
 *     pictures come out in display order with their own timestamps.
 *   - decoder_name is "vcat-vvdec-" + vvdec_get_version(), untruncated, as on Android.
 */
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vvdec/vvdec.h>

#include "vcat_decoder_plugin.h"
#include "vcat_plugin_manifest.h"

#if !defined(VCAT_PLUGIN_ID) || !defined(VCAT_PLUGIN_MIME) || !defined(VCAT_DECODER_NAME_PREFIX)
#error "vcat_plugin_manifest.h is generated from plugin.json by the build"
#endif

/* Decoded pictures not yet handed out by get_picture. vvdec_decode yields at most one picture
 * per call, and the caller drains after every send, so this rarely holds more than one. */
typedef struct frame_node {
    vvdecFrame *frame;
    struct frame_node *next;
} frame_node;

typedef struct {
    vvdecDecoder *dec;
    vvdecAccessUnit *au;     /* reused for every send; payload grown on demand */
    int32_t threads;         /* kept so reset can reopen with the same settings */
    frame_node *head, *tail;
    bool eos;                /* end_of_stream called */
    bool drained;            /* after eos: vvdec_flush reported no more pictures */
} shim_ctx;

static pthread_once_t g_name_once = PTHREAD_ONCE_INIT;
static char g_decoder_name[96];

static const char *plugin_version(void) {
    const char *v = vvdec_get_version();
    return v ? v : "unknown";
}

static void init_decoder_name(void) {
    snprintf(g_decoder_name, sizeof(g_decoder_name), "%s%s", VCAT_DECODER_NAME_PREFIX, plugin_version());
}

static const char *plugin_decoder_name(void) {
    pthread_once(&g_name_once, init_decoder_name);
    return g_decoder_name;
}

static const char *plugin_manifest_json(void) {
    return vcat_plugin_manifest;
}

static vvdecDecoder *open_decoder(int32_t threads) {
    vvdecParams params;
    vvdec_params_default(&params);
    if (threads > 0) params.threads = threads;
    return vvdec_decoder_open(&params);
}

static void enqueue(shim_ctx *ctx, vvdecFrame *frame) {
    frame_node *node = calloc(1, sizeof(*node));
    if (!node) {
        vvdec_frame_unref(ctx->dec, frame);
        return;
    }
    node->frame = frame;
    if (ctx->tail) ctx->tail->next = node; else ctx->head = node;
    ctx->tail = node;
}

static vvdecFrame *dequeue(shim_ctx *ctx) {
    frame_node *node = ctx->head;
    if (!node) return NULL;
    ctx->head = node->next;
    if (!ctx->head) ctx->tail = NULL;
    vvdecFrame *frame = node->frame;
    free(node);
    return frame;
}

static void discard_queued(shim_ctx *ctx) {
    vvdecFrame *frame;
    while ((frame = dequeue(ctx)) != NULL) vvdec_frame_unref(ctx->dec, frame);
}

static int plugin_open(const vcat_decoder_config *config, void **out_ctx) {
    if (!out_ctx) return VCAT_PLUGIN_ERROR;
    *out_ctx = NULL;

    shim_ctx *ctx = calloc(1, sizeof(*ctx));
    if (!ctx) return VCAT_PLUGIN_ERROR;
    ctx->threads = config ? config->threads : 0;
    ctx->dec = open_decoder(ctx->threads);
    ctx->au = vvdec_accessUnit_alloc();
    if (!ctx->dec || !ctx->au) {
        if (ctx->au) vvdec_accessUnit_free(ctx->au);
        if (ctx->dec) vvdec_decoder_close(ctx->dec);
        free(ctx);
        return VCAT_PLUGIN_ERROR;
    }
    vvdec_accessUnit_default(ctx->au);
    *out_ctx = ctx;
    return VCAT_PLUGIN_OK;
}

static int plugin_send_data(void *opaque, const uint8_t *data, size_t size, int64_t pts) {
    shim_ctx *ctx = opaque;
    if (!ctx) return VCAT_PLUGIN_ERROR;
    /* Every AU is consumed by the call that sends it, so there is never pending input. */
    if (!data || size == 0) return VCAT_PLUGIN_OK;
    if (ctx->eos || size > (size_t)0x7fffffff) return VCAT_PLUGIN_ERROR;

    vvdecAccessUnit *au = ctx->au;
    if (!au->payload || au->payloadSize < (int)size) {
        if (au->payload) vvdec_accessUnit_free_payload(au);
        vvdec_accessUnit_alloc_payload(au, (int)size);
        if (!au->payload) return VCAT_PLUGIN_ERROR;
    }
    memcpy(au->payload, data, size);
    au->payloadUsedSize = (int)size;
    /* Negative pts (e.g. a sentinel for a parameter-set-only AU) is clamped, not wrapped. */
    au->cts = pts < 0 ? 0 : (uint64_t)pts;
    au->ctsValid = true;

    vvdecFrame *frame = NULL;
    int rc = vvdec_decode(ctx->dec, au, &frame);
    if (frame) enqueue(ctx, frame);
    /* OK / TRY_AGAIN / EOF: consumed. Anything else: vvdec rejected this one AU -- dropped, and
     * decoding continues with the next (vvdec_jni.cc does the same). */
    (void)rc;
    return VCAT_PLUGIN_OK;
}

static int fill_picture(shim_ctx *ctx, vvdecFrame *frame, vcat_picture *out) {
    int32_t layout;
    switch (frame->colorFormat) {
        case VVDEC_CF_YUV400_PLANAR: layout = VCAT_PIXEL_LAYOUT_I400; break;
        case VVDEC_CF_YUV420_PLANAR: layout = VCAT_PIXEL_LAYOUT_I420; break;
        case VVDEC_CF_YUV422_PLANAR: layout = VCAT_PIXEL_LAYOUT_I422; break;
        case VVDEC_CF_YUV444_PLANAR: layout = VCAT_PIXEL_LAYOUT_I444; break;
        default:
            vvdec_frame_unref(ctx->dec, frame);
            return VCAT_PLUGIN_ERROR;
    }

    memset(out, 0, sizeof(*out));
    out->width = (int32_t)frame->width;
    out->height = (int32_t)frame->height;
    out->bit_depth = (int32_t)frame->bitDepth;
    out->layout = layout;
    uint32_t planes = layout == VCAT_PIXEL_LAYOUT_I400 ? 1 : 3;
    for (uint32_t i = 0; i < planes && i < frame->numPlanes; i++) {
        out->planes[i] = frame->planes[i].ptr;
        out->strides[i] = (ptrdiff_t)frame->planes[i].stride;
    }
    out->pts = frame->ctsValid ? (int64_t)frame->cts : 0;
    out->opaque = frame;
    return VCAT_PLUGIN_OK;
}

static int plugin_get_picture(void *opaque, vcat_picture *out) {
    shim_ctx *ctx = opaque;
    if (!ctx || !out) return VCAT_PLUGIN_ERROR;

    vvdecFrame *frame = dequeue(ctx);
    if (frame) return fill_picture(ctx, frame, out);

    if (!ctx->eos || ctx->drained) return VCAT_PLUGIN_AGAIN;

    /* End of stream: drain the pictures vvdec still holds for reordering. */
    frame = NULL;
    int rc = vvdec_flush(ctx->dec, &frame);
    if (!frame || rc == VVDEC_EOF) {
        if (frame) return fill_picture(ctx, frame, out);  /* last picture alongside EOF */
        ctx->drained = true;
        return VCAT_PLUGIN_AGAIN;
    }
    return fill_picture(ctx, frame, out);
}

static void plugin_release_picture(void *opaque, vcat_picture *picture) {
    shim_ctx *ctx = opaque;
    if (!ctx || !picture || !picture->opaque) return;
    vvdec_frame_unref(ctx->dec, (vvdecFrame *)picture->opaque);
    picture->opaque = NULL;
}

static void plugin_end_of_stream(void *opaque) {
    shim_ctx *ctx = opaque;
    if (ctx) ctx->eos = true;
}

/* vvdec has no "discard everything" call, so reset reopens the decoder with the same settings. */
static void plugin_reset(void *opaque) {
    shim_ctx *ctx = opaque;
    if (!ctx) return;
    discard_queued(ctx);
    vvdecDecoder *fresh = open_decoder(ctx->threads);
    if (fresh) {
        vvdec_decoder_close(ctx->dec);
        ctx->dec = fresh;
    }
    ctx->eos = false;
    ctx->drained = false;
}

static void plugin_close(void *opaque) {
    shim_ctx *ctx = opaque;
    if (!ctx) return;
    discard_queued(ctx);
    vvdec_accessUnit_free(ctx->au);
    vvdec_decoder_close(ctx->dec);
    free(ctx);
}

static const vcat_decoder_plugin g_descriptor = {
    .api_version = VCAT_PLUGIN_API_VERSION,
    .id = VCAT_PLUGIN_ID,
    .mime_type = VCAT_PLUGIN_MIME,
    .decoder_name = plugin_decoder_name,
    .version = plugin_version,
    .manifest_json = plugin_manifest_json,
    .open = plugin_open,
    .send_data = plugin_send_data,
    .get_picture = plugin_get_picture,
    .release_picture = plugin_release_picture,
    .end_of_stream = plugin_end_of_stream,
    .reset = plugin_reset,
    .close = plugin_close,
};

/* The plugin's only exported symbol -- the same name in every plugin. */
__attribute__((visibility("default")))
const vcat_decoder_plugin *vcat_plugin_entry(void) {
    return &g_descriptor;
}

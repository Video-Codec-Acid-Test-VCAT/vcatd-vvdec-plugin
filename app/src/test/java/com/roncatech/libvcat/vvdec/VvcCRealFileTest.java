package com.roncatech.libvcat.vvdec;

import org.junit.Test;
import com.roncatech.libvcat.decoder.VideoConfiguration;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;

/**
 * Parses the vvcC records lifted out of two real encodes, to find why one plays and one does not.
 *
 * vvcC_old  — plays correctly; num_bytes_constraint_info = 1
 * vvcC_new  — black screen, vvdec rejects every packet; num_bytes_constraint_info = 12
 */
public class VvcCRealFileTest {

    private static byte[] load(String name) throws Exception {
        try (InputStream in = VvcCRealFileTest.class.getClassLoader().getResourceAsStream(name)) {
            if (in == null) throw new IllegalStateException("missing resource " + name);
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
            return bos.toByteArray();
        }
    }

    private static void report(String name) throws Exception {
        byte[] data = load(name);
        System.out.println("=== " + name + " (" + data.length + " bytes)");
        try {
            VideoConfiguration cfg = VvcVideoCfgParser.parseStsd(data);
            if (cfg == null) {
                System.out.println("    parseStsd returned NULL");
                return;
            }
            System.out.println("    width=" + cfg.width + " height=" + cfg.height
                    + " nalLen=" + cfg.nalUnitLengthFieldLength
                    + " initData=" + (cfg.initializationData == null
                            ? "null" : cfg.initializationData.size() + " entries"));
            if (cfg.initializationData != null) {
                for (byte[] b : cfg.initializationData) {
                    StringBuilder sb = new StringBuilder();
                    for (int i = 0; i < Math.min(b.length, 12); i++) sb.append(String.format("%02x ", b[i]));
                    System.out.println("      nal " + b.length + "B: " + sb);
                }
            }
        } catch (Throwable t) {
            System.out.println("    THREW " + t.getClass().getName() + ": " + t.getMessage());
        }
    }

    @Test public void parseBoth() throws Exception {
        report("vvcC_old.bin");
        report("vvcC_new.bin");
    }
}

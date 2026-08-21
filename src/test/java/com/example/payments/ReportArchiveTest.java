package com.example.payments;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ReportArchiveTest {

    @TempDir
    Path tempDir;

    @Test
    void readUtf8ViaCommonsIo() throws IOException {
        Path report = tempDir.resolve("receipt.txt");
        Files.writeString(report, "ORD-1 PROCESSED", StandardCharsets.UTF_8);

        String body = new ReportArchive().readUtf8(report.toFile());

        assertEquals("ORD-1 PROCESSED", body);
    }

    @Test
    void rejectsNullFile() {
        assertThrows(NullPointerException.class, () -> new ReportArchive().readUtf8(null));
    }
}

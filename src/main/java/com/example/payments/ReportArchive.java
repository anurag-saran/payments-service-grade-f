package com.example.payments;

import org.apache.commons.io.FileUtils;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

/** Reads receipt/report files with Commons IO — reachable call site for Lightwell
 *  commons-io remediations (fast-lane demo row). */
@Component
public class ReportArchive {
    public String readUtf8(File reportFile) throws IOException {
        Objects.requireNonNull(reportFile, "reportFile");
        return FileUtils.readFileToString(reportFile, StandardCharsets.UTF_8);
    }
}

package com.example.payments;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.concurrent.Executors;

/**
 * Minimal JDK HttpServer so the shaded jar can serve canary/synthetic probes
 * without adding spring-boot-starter-web (keeps the Lightwell demo pom lean).
 */
public final class DemoHttpServer {
    private DemoHttpServer() {}

    public static HttpServer start(int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/health", DemoHttpServer::health);
        server.createContext("/api/smoke", DemoHttpServer::smoke);
        server.setExecutor(Executors.newCachedThreadPool());
        server.start();
        return server;
    }

    private static void health(HttpExchange ex) throws IOException {
        json(ex, 200, "{\"status\":\"ok\",\"service\":\"payments-service\"}");
    }

    private static void smoke(HttpExchange ex) throws IOException {
        File tmp = null;
        try {
            PaymentService payments = new PaymentService();
            String receipt = payments.process(new PaymentRequest("demo-1", 1000L, "USD"));
            tmp = Files.createTempFile("payments-smoke-", ".json").toFile();
            Files.writeString(tmp.toPath(), receipt, StandardCharsets.UTF_8);
            ReportArchive archive = new ReportArchive();
            String loaded = archive.readUtf8(tmp);
            if (receipt == null || receipt.isBlank() || loaded == null || loaded.isBlank()) {
                json(ex, 500, "{\"status\":\"error\",\"reason\":\"empty smoke result\"}");
                return;
            }
            json(ex, 200, "{\"status\":\"ok\",\"receipt_len\":" + receipt.length()
                    + ",\"archive_len\":" + loaded.length() + "}");
        } catch (Throwable t) {
            json(ex, 500, "{\"status\":\"error\",\"reason\":\""
                    + t.getClass().getSimpleName() + "\"}");
        } finally {
            if (tmp != null) {
                //noinspection ResultOfMethodCallIgnored
                tmp.delete();
            }
        }
    }

    private static void json(HttpExchange ex, int code, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().add("Content-Type", "application/json");
        ex.sendResponseHeaders(code, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }
}

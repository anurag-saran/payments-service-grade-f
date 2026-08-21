package com.example.payments;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class PaymentsApplication {
    public static void main(String[] args) throws Exception {
        SpringApplication.run(PaymentsApplication.class, args);
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        DemoHttpServer.start(port);
        System.out.println("payments-service listening on :" + port + " (/health, /api/smoke)");
        Thread.currentThread().join();
    }
}

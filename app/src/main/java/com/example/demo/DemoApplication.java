package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Demo CRUD Application
 * A simple Spring Boot application for DevOps learning.
 * 
 * Features:
 * - REST API for Item CRUD operations
 * - H2 in-memory database
 * - Actuator endpoints for health checks
 */
@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Home Controller
 * Provides basic application info and welcome message.
 */
@RestController
public class HomeController {

    @Value("${spring.application.name:Demo CRUD App}")
    private String appName;

    @Value("${app.version:1.0.0}")
    private String appVersion;

    /**
     * GET /
     * Welcome endpoint
     */
    @GetMapping("/")
    public Map<String, Object> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", appName);
        response.put("version", appVersion);
        response.put("message", "Welcome to the Demo CRUD Application!");
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("endpoints", getEndpointInfo());
        return response;
    }

    /**
     * GET /info
     * Application info endpoint
     */
    @GetMapping("/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", appName);
        response.put("version", appVersion);
        response.put("java.version", System.getProperty("java.version"));
        response.put("os.name", System.getProperty("os.name"));
        response.put("timestamp", LocalDateTime.now().toString());
        return response;
    }

    private Map<String, String> getEndpointInfo() {
        Map<String, String> endpoints = new HashMap<>();
        endpoints.put("GET /", "Application info");
        endpoints.put("GET /api/items", "Get all items");
        endpoints.put("GET /api/items/{id}", "Get item by ID");
        endpoints.put("POST /api/items", "Create new item");
        endpoints.put("PUT /api/items/{id}", "Update item");
        endpoints.put("DELETE /api/items/{id}", "Delete item");
        endpoints.put("GET /api/items/search?name=xxx", "Search items");
        endpoints.put("GET /actuator/health", "Health check");
        return endpoints;
    }
}

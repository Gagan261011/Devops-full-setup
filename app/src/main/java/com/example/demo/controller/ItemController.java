package com.example.demo.controller;

import com.example.demo.model.Item;
import com.example.demo.service.ItemService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Item Controller
 * REST API endpoints for Item CRUD operations.
 * 
 * Endpoints:
 * - GET    /api/items       - Get all items
 * - GET    /api/items/{id}  - Get item by ID
 * - POST   /api/items       - Create new item
 * - PUT    /api/items/{id}  - Update item
 * - DELETE /api/items/{id}  - Delete item
 * - GET    /api/items/search?name=xxx - Search items
 */
@RestController
@RequestMapping("/api/items")
@CrossOrigin(origins = "*")
public class ItemController {

    private final ItemService itemService;

    @Autowired
    public ItemController(ItemService itemService) {
        this.itemService = itemService;
    }

    /**
     * GET /api/items
     * Get all items
     */
    @GetMapping
    public ResponseEntity<List<Item>> getAllItems() {
        List<Item> items = itemService.getAllItems();
        return ResponseEntity.ok(items);
    }

    /**
     * GET /api/items/{id}
     * Get item by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Item> getItemById(@PathVariable Long id) {
        return itemService.getItemById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * POST /api/items
     * Create a new item
     */
    @PostMapping
    public ResponseEntity<Item> createItem(@Valid @RequestBody Item item) {
        Item createdItem = itemService.createItem(item);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdItem);
    }

    /**
     * PUT /api/items/{id}
     * Update an existing item
     */
    @PutMapping("/{id}")
    public ResponseEntity<Item> updateItem(@PathVariable Long id, 
                                            @Valid @RequestBody Item itemDetails) {
        return itemService.updateItem(id, itemDetails)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * DELETE /api/items/{id}
     * Delete an item
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteItem(@PathVariable Long id) {
        Map<String, String> response = new HashMap<>();
        
        if (itemService.deleteItem(id)) {
            response.put("message", "Item deleted successfully");
            response.put("id", id.toString());
            return ResponseEntity.ok(response);
        } else {
            response.put("error", "Item not found");
            response.put("id", id.toString());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }

    /**
     * GET /api/items/search?name=xxx
     * Search items by name
     */
    @GetMapping("/search")
    public ResponseEntity<List<Item>> searchItems(@RequestParam String name) {
        List<Item> items = itemService.searchByName(name);
        return ResponseEntity.ok(items);
    }

    /**
     * GET /api/items/count
     * Get total count of items
     */
    @GetMapping("/count")
    public ResponseEntity<Map<String, Long>> getItemCount() {
        Map<String, Long> response = new HashMap<>();
        response.put("count", itemService.getItemCount());
        return ResponseEntity.ok(response);
    }
}

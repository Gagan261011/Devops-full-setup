package com.example.demo.service;

import com.example.demo.model.Item;
import com.example.demo.repository.ItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Item Service
 * Business logic layer for Item operations.
 */
@Service
@Transactional
public class ItemService {

    private final ItemRepository itemRepository;

    @Autowired
    public ItemService(ItemRepository itemRepository) {
        this.itemRepository = itemRepository;
    }

    /**
     * Get all items
     */
    public List<Item> getAllItems() {
        return itemRepository.findAll();
    }

    /**
     * Get item by ID
     */
    public Optional<Item> getItemById(Long id) {
        return itemRepository.findById(id);
    }

    /**
     * Create a new item
     */
    public Item createItem(Item item) {
        return itemRepository.save(item);
    }

    /**
     * Update an existing item
     */
    public Optional<Item> updateItem(Long id, Item itemDetails) {
        return itemRepository.findById(id)
                .map(existingItem -> {
                    existingItem.setName(itemDetails.getName());
                    existingItem.setDescription(itemDetails.getDescription());
                    return itemRepository.save(existingItem);
                });
    }

    /**
     * Delete an item
     */
    public boolean deleteItem(Long id) {
        return itemRepository.findById(id)
                .map(item -> {
                    itemRepository.delete(item);
                    return true;
                })
                .orElse(false);
    }

    /**
     * Search items by name
     */
    public List<Item> searchByName(String name) {
        return itemRepository.findByNameContainingIgnoreCase(name);
    }

    /**
     * Get total count of items
     */
    public long getItemCount() {
        return itemRepository.count();
    }
}

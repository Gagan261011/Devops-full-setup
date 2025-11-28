package com.example.demo.repository;

import com.example.demo.model.Item;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Item Repository
 * Provides data access methods for Item entity.
 */
@Repository
public interface ItemRepository extends JpaRepository<Item, Long> {

    /**
     * Find items by name (case-insensitive contains)
     */
    List<Item> findByNameContainingIgnoreCase(String name);

    /**
     * Find items by name (exact match)
     */
    List<Item> findByName(String name);
}

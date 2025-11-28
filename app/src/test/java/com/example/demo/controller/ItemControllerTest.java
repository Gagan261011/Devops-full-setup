package com.example.demo.controller;

import com.example.demo.model.Item;
import com.example.demo.service.ItemService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for ItemController
 */
@WebMvcTest(ItemController.class)
class ItemControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ItemService itemService;

    @Autowired
    private ObjectMapper objectMapper;

    private Item testItem;

    @BeforeEach
    void setUp() {
        testItem = new Item("Test Item", "Test Description");
        testItem.setId(1L);
    }

    @Test
    void getAllItems_ShouldReturnListOfItems() throws Exception {
        List<Item> items = Arrays.asList(testItem);
        when(itemService.getAllItems()).thenReturn(items);

        mockMvc.perform(get("/api/items"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$[0].name").value("Test Item"));
    }

    @Test
    void getItemById_WhenExists_ShouldReturnItem() throws Exception {
        when(itemService.getItemById(1L)).thenReturn(Optional.of(testItem));

        mockMvc.perform(get("/api/items/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Test Item"))
                .andExpect(jsonPath("$.description").value("Test Description"));
    }

    @Test
    void getItemById_WhenNotExists_ShouldReturn404() throws Exception {
        when(itemService.getItemById(999L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/items/999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void createItem_ShouldReturnCreatedItem() throws Exception {
        Item newItem = new Item("New Item", "New Description");
        Item savedItem = new Item("New Item", "New Description");
        savedItem.setId(2L);

        when(itemService.createItem(any(Item.class))).thenReturn(savedItem);

        mockMvc.perform(post("/api/items")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(newItem)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(2))
                .andExpect(jsonPath("$.name").value("New Item"));
    }

    @Test
    void updateItem_WhenExists_ShouldReturnUpdatedItem() throws Exception {
        Item updatedItem = new Item("Updated Item", "Updated Description");
        updatedItem.setId(1L);

        when(itemService.updateItem(eq(1L), any(Item.class))).thenReturn(Optional.of(updatedItem));

        mockMvc.perform(put("/api/items/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updatedItem)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Item"));
    }

    @Test
    void deleteItem_WhenExists_ShouldReturnSuccess() throws Exception {
        when(itemService.deleteItem(1L)).thenReturn(true);

        mockMvc.perform(delete("/api/items/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Item deleted successfully"));
    }

    @Test
    void deleteItem_WhenNotExists_ShouldReturn404() throws Exception {
        when(itemService.deleteItem(999L)).thenReturn(false);

        mockMvc.perform(delete("/api/items/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Item not found"));
    }

    @Test
    void searchItems_ShouldReturnMatchingItems() throws Exception {
        List<Item> items = Arrays.asList(testItem);
        when(itemService.searchByName("Test")).thenReturn(items);

        mockMvc.perform(get("/api/items/search?name=Test"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Test Item"));
    }
}

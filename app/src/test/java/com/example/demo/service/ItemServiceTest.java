package com.example.demo.service;

import com.example.demo.model.Item;
import com.example.demo.repository.ItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for ItemService
 */
@ExtendWith(MockitoExtension.class)
class ItemServiceTest {

    @Mock
    private ItemRepository itemRepository;

    @InjectMocks
    private ItemService itemService;

    private Item testItem;

    @BeforeEach
    void setUp() {
        testItem = new Item("Test Item", "Test Description");
        testItem.setId(1L);
    }

    @Test
    void getAllItems_ShouldReturnAllItems() {
        List<Item> items = Arrays.asList(testItem);
        when(itemRepository.findAll()).thenReturn(items);

        List<Item> result = itemService.getAllItems();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Test Item");
        verify(itemRepository, times(1)).findAll();
    }

    @Test
    void getItemById_WhenExists_ShouldReturnItem() {
        when(itemRepository.findById(1L)).thenReturn(Optional.of(testItem));

        Optional<Item> result = itemService.getItemById(1L);

        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("Test Item");
    }

    @Test
    void getItemById_WhenNotExists_ShouldReturnEmpty() {
        when(itemRepository.findById(999L)).thenReturn(Optional.empty());

        Optional<Item> result = itemService.getItemById(999L);

        assertThat(result).isEmpty();
    }

    @Test
    void createItem_ShouldSaveAndReturnItem() {
        Item newItem = new Item("New Item", "New Description");
        when(itemRepository.save(any(Item.class))).thenReturn(testItem);

        Item result = itemService.createItem(newItem);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(1L);
        verify(itemRepository, times(1)).save(any(Item.class));
    }

    @Test
    void updateItem_WhenExists_ShouldUpdateAndReturnItem() {
        Item updatedDetails = new Item("Updated Name", "Updated Description");
        when(itemRepository.findById(1L)).thenReturn(Optional.of(testItem));
        when(itemRepository.save(any(Item.class))).thenReturn(testItem);

        Optional<Item> result = itemService.updateItem(1L, updatedDetails);

        assertThat(result).isPresent();
        verify(itemRepository, times(1)).save(any(Item.class));
    }

    @Test
    void deleteItem_WhenExists_ShouldReturnTrue() {
        when(itemRepository.findById(1L)).thenReturn(Optional.of(testItem));
        doNothing().when(itemRepository).delete(any(Item.class));

        boolean result = itemService.deleteItem(1L);

        assertThat(result).isTrue();
        verify(itemRepository, times(1)).delete(any(Item.class));
    }

    @Test
    void deleteItem_WhenNotExists_ShouldReturnFalse() {
        when(itemRepository.findById(999L)).thenReturn(Optional.empty());

        boolean result = itemService.deleteItem(999L);

        assertThat(result).isFalse();
        verify(itemRepository, never()).delete(any(Item.class));
    }

    @Test
    void searchByName_ShouldReturnMatchingItems() {
        List<Item> items = Arrays.asList(testItem);
        when(itemRepository.findByNameContainingIgnoreCase("Test")).thenReturn(items);

        List<Item> result = itemService.searchByName("Test");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Test Item");
    }

    @Test
    void getItemCount_ShouldReturnCount() {
        when(itemRepository.count()).thenReturn(5L);

        long count = itemService.getItemCount();

        assertThat(count).isEqualTo(5L);
    }
}

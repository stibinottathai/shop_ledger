import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/inventory/data/repositories/item_repository.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(Supabase.instance.client);
});

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<Item>>(
  () {
    return InventoryNotifier();
  },
);

class InventoryNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return ref.read(itemRepositoryProvider).getItems();
  }

  Future<void> addItem(
    String name,
    double pricePerKg,
    double? totalQuantity, {
    String unit = 'kg',
    String? barcode,
  }) async {
    // Optimistic update could be complex with ID generation, so standard async for now
    await ref
        .read(itemRepositoryProvider)
        .addItem(
          Item(
            name: name,
            pricePerKg: pricePerKg,
            totalQuantity: totalQuantity,
            unit: unit,
            barcode: barcode,
          ),
        );
    // Refresh to get new item with ID
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateItem(Item item) async {
    await ref.read(itemRepositoryProvider).updateItem(item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteItem(String id) async {
    await ref.read(itemRepositoryProvider).deleteItem(id);
    // Optimistic removal
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncData(currentState.where((e) => e.id != id).toList());
    } else {
      ref.invalidateSelf();
    }
  }

  Future<void> deleteAllItems() async {
    await ref.read(itemRepositoryProvider).deleteAllItems();
    state = const AsyncData([]);
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    return ref.read(itemRepositoryProvider).getItemByBarcode(barcode);
  }
}

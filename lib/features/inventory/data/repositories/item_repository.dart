import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';

class ItemRepository {
  final SupabaseClient _supabase;

  ItemRepository(this._supabase);

  Future<List<Item>> getItems() async {
    final response = await _supabase
        .from('items')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Item.fromJson(e)).toList();
  }

  Future<Item> addItem(Item item) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = item.toJson();
    data['user_id'] = user.id;

    final response = await _supabase
        .from('items')
        .insert(data)
        .select()
        .single();
    return Item.fromJson(response);
  }

  Future<Item> updateItem(Item item) async {
    if (item.id == null) throw Exception('Item ID is required for update');

    final response = await _supabase
        .from('items')
        .update(item.toJson())
        .eq('id', item.id!)
        .select()
        .single();
    return Item.fromJson(response);
  }

  Future<void> deleteItem(String id) async {
    await _supabase.from('items').delete().eq('id', id);
  }

  Future<void> deleteAllItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _supabase.from('items').delete().eq('user_id', user.id);
  }
}

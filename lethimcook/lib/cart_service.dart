import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_item.dart';

class CartService {
  static const _key = 'cart_items';

  static Future<List<CartItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((m) => CartItem.fromMap(m as Map<String, dynamic>)).toList();
  }

  static Future<void> _save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toMap()).toList()));
  }

  // Ajoute des ingrédients en fusionnant ceux qui ont le même nom + unité
  static Future<void> addIngredients(List<CartItem> newItems) async {
    final items = await getItems();
    for (final newItem in newItems) {
      final idx = items.indexWhere((i) =>
          i.name.toLowerCase() == newItem.name.toLowerCase() &&
          i.unit == newItem.unit);
      if (idx != -1) {
        items[idx].quantity += newItem.quantity;
      } else {
        items.add(newItem);
      }
    }
    await _save(items);
  }

  static Future<void> addItem(CartItem item) async {
    final items = await getItems();
    items.add(item);
    await _save(items);
  }

  static Future<void> updateItem(CartItem item) async {
    final items = await getItems();
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx != -1) items[idx] = item;
    await _save(items);
  }

  static Future<void> removeItem(String id) async {
    final items = await getItems();
    items.removeWhere((i) => i.id == id);
    await _save(items);
  }

  static Future<void> toggleChecked(String id) async {
    final items = await getItems();
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) items[idx].checked = !items[idx].checked;
    await _save(items);
  }

  static Future<void> clearChecked() async {
    final items = await getItems();
    items.removeWhere((i) => i.checked);
    await _save(items);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

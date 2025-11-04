// lib/database/db_helper_web.dart
import 'dart:convert';
import 'dart:html' as html;
import '../models/record.dart';

class DBHelperWeb {
  static const String _recordsKey = 'records';
  static const String _shopsKey = 'shops';

  // Record関連
  Future<List<Record>> getRecords() async {
    final jsonStr = html.window.localStorage[_recordsKey];
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => Record.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertRecord(Record record) async {
    final records = await getRecords();
    records.add(record);
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> updateRecord(int index, Record record) async {
    final records = await getRecords();
    if (index < 0 || index >= records.length) return;
    records[index] = record;
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> deleteRecord(int index) async {
    final records = await getRecords();
    if (index < 0 || index >= records.length) return;
    records.removeAt(index);
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> clearAllRecords() async {
    html.window.localStorage.remove(_recordsKey);
  }

  // Shops関連
  Future<List<String>> getShops() async {
    final jsonStr = html.window.localStorage[_shopsKey];
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertShop(String shop) async {
    final shops = await getShops();
    final lower = shop.toLowerCase();
    final exists = shops.any((s) => s.toLowerCase().trim() == lower.trim());
    if (exists) return;
    shops.add(shop);
    html.window.localStorage[_shopsKey] = jsonEncode(shops);
  }

  Future<void> deleteShop(String shop) async {
    final shops = await getShops();
    shops.removeWhere((s) => s == shop);
    html.window.localStorage[_shopsKey] = jsonEncode(shops);
  }

  Future<void> clearAllShops() async {
    html.window.localStorage.remove(_shopsKey);
  }
}

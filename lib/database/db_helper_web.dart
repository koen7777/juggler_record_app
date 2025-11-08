import 'dart:convert';
import 'dart:html' as html;
import '../models/record.dart';

class DBHelperWeb {
  static const String _recordsKey = 'records';
  static const String _shopsKey = 'shops';

  // ✅ 日付を安全にパースする
  DateTime _parseDate(String s) {
    final normalized = s.trim().replaceAll('/', '-');
    try {
      return DateTime.parse(normalized);
    } catch (_) {
      return DateTime(1900); // パースできない時の保険
    }
  }

  // ✅ 日付の降順（新しい順）でソート
  List<Record> _sortRecordsByDate(List<Record> list) {
    list.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    return list;
  }

  // ----------------------
  // Record関連
  // ----------------------
  Future<List<Record>> getRecords() async {
    final jsonStr = html.window.localStorage[_recordsKey];
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list
          .map((e) => Record.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return _sortRecordsByDate(records);
    } catch (_) {
      return [];
    }
  }

  Future<void> insertRecord(Record record) async {
    final records = await getRecords();
    records.add(record);
    _sortRecordsByDate(records); // ✅ 追加後に並び替え
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> saveAllRecords(List<Record> records) async {
    // ✅ CSV読み込み時などに使う
    final sorted = _sortRecordsByDate(records); // ✅ 並び替えをここで確実に実施
    html.window.localStorage[_recordsKey] =
        jsonEncode(sorted.map((r) => r.toMap()).toList());
  }

  Future<void> updateRecord(int index, Record record) async {
    final records = await getRecords();
    if (index < 0 || index >= records.length) return;
    records[index] = record;
    _sortRecordsByDate(records);
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> deleteRecord(int index) async {
    final records = await getRecords();
    if (index < 0 || index >= records.length) return;
    records.removeAt(index);
    _sortRecordsByDate(records);
    html.window.localStorage[_recordsKey] =
        jsonEncode(records.map((r) => r.toMap()).toList());
  }

  Future<void> clearAllRecords() async {
    html.window.localStorage.remove(_recordsKey);
  }

  // ----------------------
  // Shops関連
  // ----------------------
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

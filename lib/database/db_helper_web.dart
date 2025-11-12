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
    // 重複チェック
    if (!_exists(records, record)) {
      records.add(record);
      _sortRecordsByDate(records);
      html.window.localStorage[_recordsKey] =
          jsonEncode(records.map((r) => r.toMap()).toList());
    }
  }

  Future<void> saveAllRecords(List<Record> records) async {
    final existing = await getRecords();
    final merged = [...existing];

    for (var record in records) {
      if (!_exists(merged, record)) {
        merged.add(record);
      }
    }

    final sorted = _sortRecordsByDate(merged);
    html.window.localStorage[_recordsKey] =
        jsonEncode(sorted.map((r) => r.toMap()).toList());
  }

  // ✅ 重複チェック用関数
  bool _exists(List<Record> records, Record record) {
    return records.any((r) =>
        r.date == record.date &&
        r.machine == record.machine &&
        r.shop == record.shop &&
        r.number == record.number);
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

  // ----------------------
  // CSV読み込み用ヘルパー
  // ----------------------
  Future<void> importCsv(String csvText) async {
    final lines = csvText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    // ヘッダー除外
    final records = <Record>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');
      if (cols.length < 12) continue;
      final record = Record(
        date: cols[0],
        machine: cols[1],
        shop: cols[2],
        number: cols[3],
        totalRotation: int.tryParse(cols[4]) ?? 0,
        diff: int.tryParse(cols[5]) ?? 0,
        big: int.tryParse(cols[6]) ?? 0,
        reg: int.tryParse(cols[7]) ?? 0,
        bigDup: int.tryParse(cols[8]) ?? 0,
        regDup: int.tryParse(cols[9]) ?? 0,
        cherry: int.tryParse(cols[10]) ?? 0,
        grape: int.tryParse(cols[11]) ?? 0,
      );
      records.add(record);
    }

    await saveAllRecords(records);
  }

  // ----------------------
  // CSVエクスポート（日時付きファイル名）
  // ----------------------
  void exportRecordsToCsv(List<Record> records) {
    if (records.isEmpty) return;

    final csvHeader = [
      '日付',
      '機種名',
      '店舗名',
      '台番号',
      '総回転数',
      '差枚',
      'BIG',
      'REG',
      '重複BIG',
      '重複REG',
      'チェリー',
      'ぶどう'
    ];

    final csvRows = records.map((r) => [
          r.date,
          r.machine,
          r.shop,
          r.number,
          r.totalRotation,
          r.diff,
          r.big,
          r.reg,
          r.bigDup,
          r.regDup,
          r.cherry,
          r.grape
        ]);

    final csvContent = StringBuffer();
    csvContent.writeln(csvHeader.join(','));
    csvContent.writeAll(csvRows.map((row) => row.join(',')), '\n');

    final bytes = utf8.encode(csvContent.toString());
    final blob = html.Blob([bytes]);

    final now = DateTime.now();
    final filename =
        'juggler_data_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.csv';

    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

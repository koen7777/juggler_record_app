import 'dart:convert';
import 'dart:html' as html;
import '../models/record.dart';

class DBHelperWeb {
  static const String _recordsKey = 'records';
  static const String _shopsKey = 'shops';

  // ----------------------
  // 日付パース（安全仕様）
  // ----------------------
  DateTime _parseDate(String s) {
    final normalized = s.trim().replaceAll('/', '-');
    try {
      return DateTime.parse(normalized);
    } catch (_) {
      return DateTime(1900); // パースできない時の保険
    }
  }

  // ----------------------
  // 日付で降順ソート
  // ----------------------
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
  // CSV読み込み（ロジック部分）
  // ----------------------
  Future<void> importCsv(String csvText) async {
    if (csvText.startsWith('\uFEFF')) {
      csvText = csvText.substring(1);
    }

    csvText = csvText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = csvText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final records = <Record>[];

    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');

      if (cols.length < 12) continue;

      final record = Record(
        date: cols[0].trim(),
        machine: cols[1].trim(),
        shop: cols[2].trim(),
        number: cols[3].trim(),
        totalRotation: int.tryParse(cols[4].trim()) ?? 0,
        diff: int.tryParse(cols[5].trim()) ?? 0,
        big: int.tryParse(cols[6].trim()) ?? 0,
        reg: int.tryParse(cols[7].trim()) ?? 0,
        bigDup: int.tryParse(cols[8].trim()) ?? 0,
        regDup: int.tryParse(cols[9].trim()) ?? 0,
        cherry: int.tryParse(cols[10].trim()) ?? 0,
        grape: int.tryParse(cols[11].trim()) ?? 0,
      );

      records.add(record);
    }

    await saveAllRecords(records);
  }

  // ----------------------
  // CSVファイル選択＋読み込み（UI → ロジック）
  // ----------------------
  Future<void> importCsvFromFile() async {
    final upload = html.FileUploadInputElement();
    upload.accept = ".csv,text/csv,application/csv"; // ← 全端末対応

    upload.click();

    upload.onChange.listen((event) {
      final file = upload.files?.first;
      if (file == null) return;

      final reader = html.FileReader();

      // UTF-8 で読む（超必須）
      reader.readAsText(file, "UTF-8");

      reader.onLoadEnd.listen((event) async {
        final csvText = reader.result as String;
        await importCsv(csvText);
      });
    });
  }

  // ----------------------
  // CSVエクスポート
  // ----------------------
  void exportRecordsToCsv(List<Record> records) {
    if (records.isEmpty) return;

    final header = [
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

    final buffer = StringBuffer();
    buffer.writeln(header.join(','));
    buffer.writeAll(csvRows.map((row) => row.join(',')), '\n');

    final csv = '\uFEFF' + buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');

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

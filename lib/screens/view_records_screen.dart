// lib/screens/view_records_screen.dart

import 'package:flutter/material.dart';
import '../models/record.dart';
import '../database/db_helper_web.dart';
import 'add_record_screen.dart';

class ViewRecordsScreen extends StatefulWidget {
  const ViewRecordsScreen({super.key});

  @override
  State<ViewRecordsScreen> createState() => _ViewRecordsScreenState();
}

class _ViewRecordsScreenState extends State<ViewRecordsScreen> {
  final DBHelperWeb _dbHelper = DBHelperWeb();
  List<Record> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _dbHelper.getRecords();

    // ✅ 日付で新しい順（降順）にソート
    records.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date.replaceAll('/', '-'));
      DateTime dateB = DateTime.parse(b.date.replaceAll('/', '-'));
      return dateB.compareTo(dateA);
    });

    setState(() => _records = records);
  }

  Future<void> _deleteRecord(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このデータを本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final records = await _dbHelper.getRecords();
      if (index < 0 || index >= records.length) return;

      records.removeAt(index);
      await _dbHelper.clearAllRecords();
      for (final r in records) {
        await _dbHelper.insertRecord(r);
      }

      _loadRecords();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('データ閲覧')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final r = _records[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text('${r.date} / ${r.machine}'),
              subtitle: Text(
                '店舗: ${r.shop}  台:${r.number}\n'
                '総回転数: ${r.totalRotation} / 差枚: ${r.diff}\n'
                'BIG: ${r.big} / REG: ${r.reg}\n'
                '重複BIG: ${r.bigDup} / 重複REG: ${r.regDup}\n'
                'チェリー: ${r.cherry} / ぶどう: ${r.grape}',
                style: const TextStyle(fontSize: 13),
              ),

              // ✅ ゴミ箱に薄い赤背景
              trailing: GestureDetector(
                onTap: () => _deleteRecord(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ),

              onTap: () async {
                final edit = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('データ編集'),
                    content: const Text('このデータを修正しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('修正する'),
                      ),
                    ],
                  ),
                );

                if (edit == true) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRecordScreen(
                        record: r,
                        recordIndex: index,
                      ),
                    ),
                  );
                  _loadRecords();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

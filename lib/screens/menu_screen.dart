// lib/screens/menu_screen.dart

import 'dart:convert';
import 'dart:html' as html;

// Flutter Web: HTML element を表示
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'add_record_screen.dart';
import 'view_records_screen.dart';
import 'shops_screen.dart';
import '../database/db_helper_web.dart';
import '../models/record.dart';
import 'data_list/data_list_screen.dart';
import 'about_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final dbHelper = DBHelperWeb();

  @override
  void initState() {
    super.initState();

    // ★ ここは残してOK（下部広告用の viewType 登録）
    if (kIsWeb) {
      ui.platformViewRegistry.registerViewFactory(
        'adstir-banner',
        (int viewId) {
          final container = html.DivElement()
            ..id = 'adstir-area-$viewId'
            ..style.width = '320px'
            ..style.height = '100px'
            ..style.margin = '0'
            ..style.padding = '0'
            ..style.overflow = 'hidden';

          final adDiv = html.DivElement()
            ..id = 'adstir_$viewId'
            ..style.width = '320px'
            ..style.height = '100px';

          container.append(adDiv);

          final configScript = html.ScriptElement()
            ..type = 'text/javascript'
            ..text = '''
              window.adstir_vars = {
                ver: "4.0",
                app_id: "MEDIA-d51fb80d",
                ad_spot: 1,
                center: true
              };
            ''';

          container.append(configScript);

          final jsScript = html.ScriptElement()
            ..type = 'text/javascript'
            ..src = "https://js.ad-stir.com/js/adstir.js";

          container.append(jsScript);

          return container;
        },
      );
    }
  }

  // CSV エクスポート
  Future<void> _exportCSV() async {
    final records = await dbHelper.getRecords();
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存データがありません')),
      );
      return;
    }

    final header = [
      '日付', '機種名', '店舗名', '台番号', '総回転数', '差枚',
      'BIG', 'REG', '重複BIG', '重複REG', 'チェリー', 'ぶどう'
    ];
    final rows = records.map((r) => r.toCsvRow().join(',')).join('\n');
    final csvData = '${header.join(',')}\n$rows';

    final blob = html.Blob([utf8.encode(csvData)], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'records.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('CSVをエクスポートしました')));
  }

  // CSV インポート
  void _importCSV() {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoadEnd.listen((event) async {
        final text = reader.result as String;
        final lines = const LineSplitter().convert(text);
        if (lines.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVにデータがありません')),
          );
          return;
        }

        for (int i = 1; i < lines.length; i++) {
          final raw = lines[i].trim();
          if (raw.isEmpty) continue;

          final cols = raw.split(',');
          if (cols.length < 12) continue;

          final record = Record.fromCsvRow(
            cols.map((e) => e.trim()).toList(),
          );
          await dbHelper.insertRecord(record);

          if (record.shop.trim().isNotEmpty) {
            await dbHelper.insertShop(record.shop.trim());
          }
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CSVをインポートしました')));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メニュー')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ★★ ここにあった上部広告は完全削除 ★★
            // 広告による高さ100pxの余白も消える

            const Text(
              'このアプリは、自分がプレイしたパチスロのデータを記録・管理し、'
              '統計やグラフで分析できるツールです。勝ち方の指南はありません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            _menuButton(context, 'データ入力', const AddRecordScreen()),
            const SizedBox(height: 12),
            _menuButton(context, 'データ閲覧', const ViewRecordsScreen()),
            const SizedBox(height: 12),
            _menuButton(context, '店舗登録', const ShopsScreen()),
            const SizedBox(height: 12),
            _menuButton(context, 'データ一覧', const DataListScreen()),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 12),

            _coloredButton(
              context,
              'CSVをエクスポート（保存）',
              _exportCSV,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            ),
            const SizedBox(height: 12),

            _coloredButton(
              context,
              'CSVをインポート（読み込み）',
              _importCSV,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: const Text(
                '⚠️ 注意 ⚠️\nブラウザの更新やキャッシュ削除でデータが消えることがあります。\n必ずCSVでバックアップしてください。',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            _coloredButton(
              context,
              'このアプリについて',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String title, Widget screen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(title),
      ),
    );
  }

  Widget _coloredButton(
    BuildContext context,
    String title,
    VoidCallback onPressed, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

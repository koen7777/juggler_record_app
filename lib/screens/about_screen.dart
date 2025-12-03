// lib/screens/about_screen.dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('このアプリについて')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text(
              'このアプリは、ユーザーが自分でプレイしたパチスロのデータを記録・管理し、'
              '統計やグラフで分析できるツールです。アプリ内で勝ち方や攻略方法を提示するものではありません。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '主な機能：\n'
              '・日付・店舗・台番号・差枚数などのプレイデータの保存\n'
              '・CSVによるデータのインポート・エクスポート\n'
              '・記録データを基にした集計、グラフ表示',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '注意事項：\n'
              '・ブラウザの更新やキャッシュ削除でデータが消えることがあります。\n'
              '・必ずCSVでバックアップしてください。\n'
              '・本アプリは18歳未満の方は利用できません。\n'
              '・本アプリの利用による損害について、作者は一切責任を負いません。',
              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '著作権・権利表示：\n'
              '© 2025 こえん All Rights Reserved\n'
              'アプリのコード、デザイン、ロゴなどすべての権利は作者に帰属します。',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              '利用規約：\n'
              '・本アプリは個人用のデータ管理・分析ツールです。\n'
              '・アプリ内でのプレイ結果の公開や共有は自己責任で行ってください。\n'
              '・本アプリはギャンブル行為を推奨するものではありません。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

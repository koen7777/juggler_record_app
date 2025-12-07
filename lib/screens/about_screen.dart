import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    // Web / iOS / Android すべてで確実に開く
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('このアプリについて')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'このアプリは、ユーザーが自分でプレイしたパチスロのデータを記録・管理し、'
              '統計やグラフで分析できるWebアプリです。攻略情報を提供するものではありません。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            const Text(
              '主な機能：\n'
              '・日付・店舗・台番号・差枚数などのプレイデータの保存\n'
              '・CSVによるデータのインポート・エクスポート\n'
              '・集計、分析、グラフ表示\n',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            const Text(
              '注意事項：\n'
              '・ブラウザの更新やキャッシュ削除でデータが消えることがあります。\n'
              '・必ずCSVでバックアップしてください。\n'
              '・本アプリは18歳未満の方は利用できません。\n'
              '・本アプリの利用による損害について、作者は一切責任を負いません。',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '著作権・権利表示：\n'
              '© 2025 こえん All Rights Reserved\n'
              'アプリのコード、デザイン、ロゴなどすべての権利は作者に帰属します。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            const Text(
              '利用規約：\n'
              '・本アプリは個人用のデータ管理・分析ツールです。\n'
              '・アプリ内でのプレイ結果の公開や共有は自己責任で行ってください。\n'
              '・本アプリはギャンブル行為を推奨するものではありません。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),

            const Divider(height: 32),
            const Text(
              '広告サービス / プライバシーについて',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            const Text(
              '本アプリでは、広告配信の最適化のため ID5 技術を利用しています。',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),

            // 🔗 🔗 🔗 ID5 オプトアウトリンク（重要）
            TextButton(
              onPressed: () => _openUrl(
                "https://id5.io/jp/platform-privacy-policy/",
              ),
              child: const Text(
                "ID5 プラットフォーム・プライバシーポリシー（オプトアウトはこちら）",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

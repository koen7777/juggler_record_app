import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';

class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key});

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  final DBHelperWeb _db = DBHelperWeb();
  List<Record> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ✅ 最新日付が先頭になるように読み込み
  Future<void> _loadRecords() async {
    final records = await _db.getRecords();
    setState(() {
      _records = records; // DBHelperWebで新しい順にソート済み
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _records.isNotEmpty;
    final todayRecord = hasData ? _records.first : null; // ✅ 最新データを今日扱い

    return Scaffold(
      appBar: AppBar(title: const Text('データ一覧（Dashboard）')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _todayCard(todayRecord),
            const SizedBox(height: 24),

            const Text(
              "📅 直近の履歴",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (hasData)
              ..._records.take(3).map((r) => _historyCard(r)).toList() // ✅ そのまま上から3件
            else
              const Center(child: Text("データがありません")),

            const SizedBox(height: 24),

            const Text(
              "📊 集計メニュー",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _gridMenu(context),
          ],
        ),
      ),
    );
  }

  // ✅ 今日の成績カード
  Widget _todayCard(Record? record) {
    if (record == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text("データがまだありません")),
        ),
      );
    }

    // 出現率・ペイアウト計算（保存ではなく計算表示のみ）
    final bigRate = record.big == 0
        ? "-"
        : "1/${(record.totalRotation / record.big).toStringAsFixed(0)}";
    final regRate = record.reg == 0
        ? "-"
        : "1/${(record.totalRotation / record.reg).toStringAsFixed(0)}";
    final bigDupRate = record.bigDup == 0
        ? "-"
        : "1/${(record.totalRotation / record.bigDup).toStringAsFixed(0)}";
    final regDupRate = record.regDup == 0
        ? "-"
        : "1/${(record.totalRotation / record.regDup).toStringAsFixed(0)}";
    final cherryRate = record.cherry == 0
        ? "-"
        : "1/${(record.totalRotation / record.cherry).toStringAsFixed(1)}";
    final grapeRate = record.grape == 0
        ? "-"
        : "1/${(record.totalRotation / record.grape).toStringAsFixed(2)}";

    final payout = record.totalRotation == 0
        ? "-"
        : "${((record.diff / (record.totalRotation * 3)) * 100 + 100).toStringAsFixed(1)}%";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📅 今日の成績",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Text("差枚：${record.diff >= 0 ? '+' : ''}${record.diff}枚",
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("総回転数：${record.totalRotation}G"),
            Text("ペイアウト：$payout"),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            Text("BIG ${record.big}回 ($bigRate)   REG ${record.reg}回 ($regRate)",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
                "重複BIG ${record.bigDup}回 ($bigDupRate)   重複REG ${record.regDup}回 ($regDupRate)",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
                "チェリー ${record.cherry}回 ($cherryRate)   ぶどう ${record.grape}回 ($grapeRate)",
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ✅ 履歴カード（直近3件）
  Widget _historyCard(Record record) {
    final diffText = "${record.diff >= 0 ? '+' : ''}${record.diff}枚";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "📅 ${record.date}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(record.machine, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(diffText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: record.diff < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 2,
              child: Text("${record.totalRotation}G",
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 固定の3列メニュー
  Widget _gridMenu(BuildContext context) {
    final menuItems = [
      ("日別", Icons.calendar_today),
      ("機種別", Icons.games),
      ("店舗別", Icons.store),
      ("通算", Icons.assessment),
      ("末尾別", Icons.tag),
      ("特定日", Icons.star),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: menuItems.map((item) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${item.$1}：開発中です")),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$2, size: 24),
              const SizedBox(height: 6),
              Text(
                item.$1,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

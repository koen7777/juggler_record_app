import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import 'graph_screen.dart';
import '../aggregation/daily_summary_screen.dart'; // ← 日別集計画面
import '../aggregation/machine_summary_screen.dart'; // ← 機種別集計画面
import '../aggregation/store_summary_screen.dart'; // パスと小文字を確認
import '../aggregation/total_summary_screen.dart';
import '../aggregation/tail_summary_screen.dart'; // 
import '../aggregation/specific_day_summary_screen.dart';


// 🟢 メニュー用クラス
class MenuItem {
  final String title;
  final IconData icon;
  final Widget? screen;

  MenuItem(this.title, this.icon, this.screen);
}

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

  Future<void> _loadRecords() async {
    final records = await _db.getRecords();
    setState(() {
      _records = records; // DBHelperWebで新しい順にソート済み
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _records.isNotEmpty;
    final todayRecord = hasData ? _records.first : null; // 最新データを今日扱い

    return Scaffold(
      appBar: AppBar(title: const Text('データ一覧（Dashboard）')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📊 今日の成績カードをタップでGraphScreenへ遷移
            GestureDetector(
              onTap: hasData
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GraphScreen(records: _records),
                        ),
                      );
                    }
                  : null,
              child: _todayCard(todayRecord),
            ),
            const SizedBox(height: 24),

            const Text(
              "📅 直近の履歴",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (hasData)
              ..._records.take(3).map((r) => _historyCard(r)).toList()
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

  // 🟩 今日の成績カード
  Widget _todayCard(Record? record) {
    if (record == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text("データがまだありません")),
        ),
      );
    }

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

    final payoutValue = record.totalRotation == 0
        ? 0.0
        : ((record.diff / (record.totalRotation * 3)) * 100 + 100);

    // 🔹 追加分計算
    final totalBonus = record.big + record.reg + record.bigDup + record.regDup;
    final totalBonusRate = totalBonus == 0
        ? "-"
        : "1/${(record.totalRotation / totalBonus).toStringAsFixed(2)}";

    final bigTotal = record.big + record.bigDup;
    final bigTotalRate =
        bigTotal == 0 ? "-" : "1/${(record.totalRotation / bigTotal).toStringAsFixed(2)}";

    final regTotal = record.reg + record.regDup;
    final regTotalRate =
        regTotal == 0 ? "-" : "1/${(record.totalRotation / regTotal).toStringAsFixed(2)}";

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
            Row(
              children: [
                const Text("差枚：",
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(
                  "${record.diff >= 0 ? '+' : ''}${record.diff}枚",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: record.diff < 0 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("総回転数：${record.totalRotation}G"),
            Row(
              children: [
                const Text("ペイアウト率："),
                Text(
                  "${payoutValue.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: payoutValue < 100 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
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
            Text("チェリー ${record.cherry}回 ($cherryRate)   ぶどう ${record.grape}回 ($grapeRate)",
                style: const TextStyle(fontSize: 14)),

            // 🔹 ここから追加
            const SizedBox(height: 8),
            Text("ボーナス合計: $totalBonus回  合算確率: $totalBonusRate",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
                "BIG合計: $bigTotal回  合算確率: $bigTotalRate   REG合計: $regTotal回  合算確率: $regTotalRate",
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // 🟩 履歴カード（直近3件）
  Widget _historyCard(Record record) {
    final payoutValue = record.totalRotation == 0
        ? 0.0
        : ((record.diff / (record.totalRotation * 3)) * 100 + 100);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                flex: 3,
                child: Text("📅 ${record.date}",
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 5, child: Text(record.machine, overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 2,
              child: Text(
                "${record.diff >= 0 ? '+' : ''}${record.diff}枚",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: record.diff < 0 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text("${record.totalRotation}G",
                  textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${payoutValue.toStringAsFixed(1)}%",
                textAlign: TextAlign.right,
                style: TextStyle(color: payoutValue < 100 ? Colors.red : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟩 固定の3列メニュー（修正版）
  Widget _gridMenu(BuildContext context) {
    final menuItems = [
      MenuItem("日別", Icons.calendar_today, const DailySummaryScreen()),
      MenuItem("機種別", Icons.games, MachineSummaryScreen()), // ← const 外す
      MenuItem("店舗別", Icons.store, const ShopSummaryScreen()),
      MenuItem("通算", Icons.assessment, const TotalSummaryScreen()),
      MenuItem("末尾別", Icons.tag, const TailSummaryScreen()),
      MenuItem("特定日", Icons.star, const SpecificDaySummaryScreen()),

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          ),
          onPressed: () {
            if (item.screen != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen!));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${item.title}：開発中です")),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 24),
              const SizedBox(height: 6),
              Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

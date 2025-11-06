import 'package:flutter/material.dart';

class DataListScreen extends StatelessWidget {
  const DataListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('データ一覧（Dashboard）')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _todayCard(),
            const SizedBox(height: 24),

            const Text(
              "📅 直近の履歴",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _historyCard(
              date: "11/05",
              machine: "アイムジャグラー",
              diff: "+850枚",
              games: 4120,
            ),
            _historyCard(
              date: "11/04",
              machine: "マイジャグV",
              diff: "-200枚",
              games: 3250,
            ),
            _historyCard(
              date: "11/03",
              machine: "アイムジャグラー",
              diff: "+50枚",
              games: 2750,
            ),

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

  // ✅ 今日の成績カード（あなたの配置案）
  Widget _todayCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("📅 今日の成績",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Text("差枚：+850枚",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("総回転数：4120G"),
            Text("ペイアウト：103.2%"),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),

            Text(
              "BIG 14回 (1/100)   REG 2回 (1/111)",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              "重複BIG 3回 (1/254)   重複REG 5回 (1/50)",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              "チェリー 56回 (1/63)   ぶどう 144回 (1/7.58)",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 履歴カード
  Widget _historyCard({
    required String date,
    required String machine,
    required String diff,
    required int games,
  }) {
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
                "📅 $date",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(machine, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(diff,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: diff.startsWith('-') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 2,
              child: Text("${games}G",
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 3列グリッドメニュー
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
          onPressed: () {},
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

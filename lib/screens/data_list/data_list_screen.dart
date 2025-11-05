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

            /// ✅ ダミー履歴（確率なしで横並び）
            _historyCard(
              date: "11/05",
              machine: "アイムジャグラー",
              diff: "+850枚",
              games: 4120,
              payout: 103.2,
              big: 14, reg: 2, dupBig: 3, dupReg: 5,
              cherry: 56, grape: 144,
            ),
            _historyCard(
              date: "11/04",
              machine: "マイジャグV",
              diff: "-200枚",
              games: 3250,
              payout: 98.4,
              big: 9, reg: 6, dupBig: 1, dupReg: 2,
              cherry: 40, grape: 130,
            ),
            _historyCard(
              date: "11/03",
              machine: "アイムジャグラー",
              diff: "+50枚",
              games: 2750,
              payout: 100.8,
              big: 10, reg: 5, dupBig: 2, dupReg: 1,
              cherry: 30, grape: 110,
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

  /// ✅ 今日の成績
  Widget _todayCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("📅 今日の成績", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("差枚：+850枚", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("総回転数：4120G"),
            Text("ペイアウト：103.2%"),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Text("BIG 14回 (1/100)   REG 2回 (1/111)   重複BIG 3回 (1/254)   重複REG 5回 (1/50)",
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 6),
            Text("チェリー 56回 (1/63)   ぶどう 144回 (1/7.58)", style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  /// ✅ 直近履歴カード（回数のみ 横1列）
  Widget _historyCard({
    required String date,
    required String machine,
    required String diff,
    required int games,
    required double payout,
    required int big,
    required int reg,
    required int dupBig,
    required int dupReg,
    required int cherry,
    required int grape,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("📅 $date  $machine  差枚：$diff / ${games}G / ${payout.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            "BIG $big  REG $reg  重複BIG $dupBig  重複REG $dupReg  チェリー $cherry  ぶどう $grape",
            style: const TextStyle(fontSize: 12),
          ),
        ]),
      ),
    );
  }

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
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: menuItems.map((item) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$2, size: 32),
              const SizedBox(height: 8),
              Text(item.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

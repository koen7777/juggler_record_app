// lib/screens/aggregation/store_summary_screen.dart

import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import '../aggregation/machine_graph_screen.dart';

class ShopSummaryScreen extends StatefulWidget {
  const ShopSummaryScreen({super.key});

  @override
  State<ShopSummaryScreen> createState() => _ShopSummaryScreenState();
}

class _ShopSummaryScreenState extends State<ShopSummaryScreen> {
  final DBHelperWeb _db = DBHelperWeb();
  Map<String, List<Record>> grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getRecords();
    final map = <String, List<Record>>{};

    for (var r in list) {
      map.putIfAbsent(r.shop, () => []).add(r);
    }

    setState(() {
      grouped = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("店舗別集計")),
      body: grouped.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries
                  .map((e) => _shopCard(e.key, e.value))
                  .toList(),
            ),
    );
  }

  Widget _shopCard(String shop, List<Record> records) {
    final totalGames =
        records.fold<int>(0, (sum, r) => sum + r.totalRotation);
    final totalDiff = records.fold<int>(0, (sum, r) => sum + r.diff);

    final totalBig = records.fold<int>(0, (sum, r) => sum + r.big);
    final totalBigDup = records.fold<int>(0, (sum, r) => sum + r.bigDup);
    final totalReg = records.fold<int>(0, (sum, r) => sum + r.reg);
    final totalRegDup = records.fold<int>(0, (sum, r) => sum + r.regDup);
    final totalCherry = records.fold<int>(0, (sum, r) => sum + r.cherry);
    final totalGrape = records.fold<int>(0, (sum, r) => sum + r.grape);

    final totalBonus = totalBig + totalBigDup + totalReg + totalRegDup;
    final bigTotal = totalBig + totalBigDup;
    final regTotal = totalReg + totalRegDup;

    final payout = totalGames == 0
        ? 0
        : ((totalDiff / (totalGames * 3)) * 100 + 100);

    String rate(int count) =>
        count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

    bool isExpanded = false;

    // 勝率計算
    final winCount = records.where((r) => r.diff > 0).length;
    final winRate = records.isEmpty ? 0 : (winCount / records.length) * 100;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Stack(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(shop,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "差枚：${totalDiff >= 0 ? '+' : ''}$totalDiff枚 / 総回転数：$totalGames G",
                  style: const TextStyle(fontSize: 14),
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                initiallyExpanded: false,
                onExpansionChanged: (expanded) {
                  setInnerState(() => isExpanded = expanded);
                },
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("差枚：",
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(
                            "${totalDiff >= 0 ? '+' : ''}$totalDiff枚",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: totalDiff < 0 ? Colors.red : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("総回転数：$totalGames G"),
                      Text(
                        "ペイアウト：${payout.toStringAsFixed(1)}%",
                        style: TextStyle(
                            color: payout < 100 ? Colors.red : Colors.black),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                          "BIG $totalBig回 (${rate(totalBig)})   REG $totalReg回 (${rate(totalReg)})"),
                      const SizedBox(height: 6),
                      Text(
                          "重複BIG $totalBigDup回 (${rate(totalBigDup)})   重複REG $totalRegDup回 (${rate(totalRegDup)})"),
                      const SizedBox(height: 6),
                      Text(
                          "チェリー $totalCherry回 (${rate(totalCherry)})   ぶどう $totalGrape回 (${rate(totalGrape)})"),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                          "ボーナス合計: $totalBonus回  合算: ${rate(totalBonus)}"),
                      Text(
                          "BIG合計: $bigTotal回 (${rate(bigTotal)})   REG合計: $regTotal回 (${rate(regTotal)})"),
                      const SizedBox(height: 6),
                      // プレイ回数と勝率表示
                      Text(
                        "プレイ回数：${records.length}回  勝率：${winRate.toStringAsFixed(1)}%",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ],
              ),
            ),

            // 🔹 グラフボタン（展開時のみ右下表示）
            if (isExpanded)
              Positioned(
                bottom: 24,  // 縦位置調整
                right: 16,   // 横位置調整
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MachineGraphScreen(records: records),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.show_chart, color: Colors.white),
                        SizedBox(height: 2),
                        Text(
                          "グラフ",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

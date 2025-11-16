import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';

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
              children: grouped.entries.map((e) => _shopCard(e.key, e.value)).toList(),
            ),
    );
  }

  Widget _shopCard(String shop, List<Record> records) {
    final totalGames = records.fold<int>(0, (sum, r) => sum + r.totalRotation);
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

    final payout = totalGames == 0 ? 0 : ((totalDiff / (totalGames * 3)) * 100 + 100);
    String rate(int count) =>
        count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(shop, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(
          "差枚：${totalDiff >= 0 ? '+' : ''}$totalDiff枚 / 総回転数：$totalGames G",
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("差枚：",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 4),
                Text("総回転数：$totalGames G"),
                Text(
                  "ペイアウト：${payout.toStringAsFixed(1)}%",
                  style: TextStyle(color: payout < 100 ? Colors.red : Colors.black),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                    "BIG $totalBig回 (${rate(totalBig)})   REG $totalReg回 (${rate(totalReg)})"),
                const SizedBox(height: 4),
                Text(
                    "重複BIG $totalBigDup回 (${rate(totalBigDup)})   重複REG $totalRegDup回 (${rate(totalRegDup)})"),
                const SizedBox(height: 4),
                Text(
                    "チェリー $totalCherry回 (${rate(totalCherry)})   ぶどう $totalGrape回 (${rate(totalGrape)})"),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text("ボーナス合計: $totalBonus回  合算: ${rate(totalBonus)}"),
                Text("BIG合計: $bigTotal回 (${rate(bigTotal)})   REG合計: $regTotal回 (${rate(regTotal)})"),
                const SizedBox(height: 4),
                Text("プレイ回数：${records.length}回", style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';

class MachineSummaryScreen extends StatefulWidget {
  const MachineSummaryScreen({super.key});

  @override
  State<MachineSummaryScreen> createState() => _MachineSummaryScreenState();
}

class _MachineSummaryScreenState extends State<MachineSummaryScreen> {
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
      if (!map.containsKey(r.machine)) map[r.machine] = [];
      map[r.machine]!.add(r);
    }

    setState(() {
      grouped = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("機種別 集計")),
      body: grouped.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((e) {
                return _machineCard(e.key, e.value);
              }).toList(),
            ),
    );
  }

  Widget _machineCard(String machine, List<Record> records) {
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

    String rate(int count) => count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 機種名
            Text(machine, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 差枚・総回転数・ペイアウト率
            Row(
              children: [
                const Text("差枚：", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
            Row(
              children: [
                const Text("ペイアウト率："),
                Text(
                  "${payout.toStringAsFixed(1)}%",
                  style: TextStyle(color: payout < 100 ? Colors.red : Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // BIG/REG/重複/チェリー/ぶどう
            Text("BIG $totalBig回 (${rate(totalBig)})   REG $totalReg回 (${rate(totalReg)})",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text("重複BIG $totalBigDup回 (${rate(totalBigDup)})   重複REG $totalRegDup回 (${rate(totalRegDup)})",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text("チェリー $totalCherry回 (${rate(totalCherry)})   ぶどう $totalGrape回 (${rate(totalGrape)})",
                style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // ボーナス合計・BIG合計・REG合計・プレイ回数
            Text("ボーナス合計: $totalBonus回  合算確率: ${rate(totalBonus)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text("BIG合計: $bigTotal回  合算確率: ${rate(bigTotal)}   REG合計: $regTotal回  合算確率: ${rate(regTotal)}",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text("プレイ回数：${records.length}回", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import '../aggregation/machine_graph_screen.dart';

class TotalSummaryScreen extends StatefulWidget {
  const TotalSummaryScreen({super.key});

  @override
  State<TotalSummaryScreen> createState() => _TotalSummaryScreenState();
}

class _TotalSummaryScreenState extends State<TotalSummaryScreen> {
  final DBHelperWeb _db = DBHelperWeb();

  List<Record> allRecords = [];

  int totalGames = 0;
  int totalDiff = 0;
  int totalBig = 0;
  int totalBigDup = 0;
  int totalReg = 0;
  int totalRegDup = 0;
  int totalCherry = 0;
  int totalGrape = 0;
  int totalBonus = 0;
  int bigTotal = 0;
  int regTotal = 0;
  double payout = 0;
  int playCount = 0;
  double winRate = 0;

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getRecords();
    allRecords = list;

    playCount = list.length;
    totalGames = list.fold(0, (sum, r) => sum + r.totalRotation);
    totalDiff = list.fold(0, (sum, r) => sum + r.diff);
    totalBig = list.fold(0, (sum, r) => sum + r.big);
    totalBigDup = list.fold(0, (sum, r) => sum + r.bigDup);
    totalReg = list.fold(0, (sum, r) => sum + r.reg);
    totalRegDup = list.fold(0, (sum, r) => sum + r.regDup);
    totalCherry = list.fold(0, (sum, r) => sum + r.cherry);
    totalGrape = list.fold(0, (sum, r) => sum + r.grape);
    totalBonus = totalBig + totalBigDup + totalReg + totalRegDup;
    bigTotal = totalBig + totalBigDup;
    regTotal = totalReg + totalRegDup;
    payout = totalGames == 0 ? 0 : ((totalDiff / (totalGames * 3)) * 100 + 100);
    final winCount = list.where((r) => r.diff > 0).length;
    winRate = playCount == 0 ? 0 : (winCount / playCount) * 100;

    setState(() => isLoaded = true);
  }

  String rate(int count) =>
      count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("通算成績")),
      body: !isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    bool isExpanded = true;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        onExpansionChanged: (value) =>
                            setInnerState(() => isExpanded = value),
                        title: const Text(
                          "通算成績",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "差枚：${totalDiff >= 0 ? '+' : ''}$totalDiff枚 / 総回転数：$totalGames G",
                          style: const TextStyle(fontSize: 14),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        children: [
                          Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    "差枚",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${totalDiff >= 0 ? '+' : ''}$totalDiff枚",
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: totalDiff < 0
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Text("総回転数：$totalGames G"),
                                  Text(
                                    "ペイアウト：${payout.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                        color: payout < 100
                                            ? Colors.red
                                            : Colors.black),
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
                                      "BIG合計: $bigTotal回 (${rate(bigTotal)})   REG合計: ${regTotal}回 (${rate(regTotal)})"),
                                  const SizedBox(height: 10),
                                  Text(
                                    "プレイ回数：$playCount回  勝率：${winRate.toStringAsFixed(1)}%",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                              // グラフボタンはカード内の右下に配置
                              if (isExpanded)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MachineGraphScreen(
                                              records: allRecords),
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
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

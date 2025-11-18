import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import '../aggregation/machine_graph_screen.dart';

enum TailMode { lastDigit, doubleDigit, specific }

class TailSummaryScreen extends StatefulWidget {
  const TailSummaryScreen({super.key});

  @override
  State<TailSummaryScreen> createState() => _TailSummaryScreenState();
}

class _TailSummaryScreenState extends State<TailSummaryScreen> {
  final DBHelperWeb _db = DBHelperWeb();
  List<Record> allRecords = [];
  TailMode mode = TailMode.lastDigit;

  List<String> specificNumbers = []; // 特定台番号リスト
  Map<String, List<Record>> grouped = {};
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getRecords();
    allRecords = list;
    _groupRecords();
    setState(() => isLoaded = true);
  }

  // 🔹 下2桁以上がすべて同じ数字か判定
  bool _isTailDoubleDigit(String number) {
    if (number.length < 2) return false;
    for (int len = 2; len <= number.length; len++) {
      String tail = number.substring(number.length - len);
      if (tail.split('').every((d) => d == tail[0])) return true;
    }
    return false;
  }

  void _groupRecords() {
    final map = <String, List<Record>>{};

    switch (mode) {
      case TailMode.lastDigit:
        for (var r in allRecords) {
          if (r.number.isEmpty) continue;
          String tail = r.number[r.number.length - 1];
          map.putIfAbsent(tail, () => []).add(r);
        }
        // 0～9を必ず表示
        for (var i = 0; i <= 9; i++) {
          map.putIfAbsent(i.toString(), () => []);
        }
        // 0-9順に整列
        grouped = Map.fromEntries(List.generate(10, (i) => i.toString())
            .map((k) => MapEntry(k, map[k]!)));
        break;

      case TailMode.doubleDigit:
        for (var r in allRecords) {
          if (r.number.isEmpty) continue;
          if (_isTailDoubleDigit(r.number)) {
            map.putIfAbsent(r.number, () => []).add(r);
          }
        }
        // 台番号順に整列
        final sortedKeys = map.keys.map(int.parse).toList()..sort();
        grouped = Map.fromEntries(
            sortedKeys.map((k) => MapEntry(k.toString(), map[k.toString()]!)));
        break;

      case TailMode.specific:
        for (var r in allRecords) {
          if (specificNumbers.contains(r.number)) {
            map.putIfAbsent(r.number, () => []).add(r);
          }
        }
        // 特定番号も台番号順に整列
        final sortedKeys = map.keys.map(int.parse).toList()..sort();
        grouped = Map.fromEntries(
            sortedKeys.map((k) => MapEntry(k.toString(), map[k.toString()]!)));
        break;
    }
  }

  void _changeMode(TailMode newMode) async {
    if (newMode == TailMode.specific) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => _NumberInputDialog(initial: specificNumbers),
      );
      if (result != null) {
        specificNumbers = result;
      }
    }

    setState(() {
      mode = newMode;
      _groupRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("台番号集計")),
      body: !isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () => _changeMode(TailMode.lastDigit),
                          child: const Text("末尾別")),
                      ElevatedButton(
                          onPressed: () => _changeMode(TailMode.doubleDigit),
                          child: const Text("ゾロ目")),
                      ElevatedButton(
                          onPressed: () => _changeMode(TailMode.specific),
                          child: const Text("特定台番号")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: grouped.isEmpty
                      ? const Center(child: Text("該当データなし"))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: grouped.entries
                              .map((e) => _tailCard(e.key, e.value))
                              .toList(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tailCard(String tail, List<Record> records) {
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

    final payout = totalGames == 0
        ? 0
        : ((totalDiff / (totalGames * 3)) * 100 + 100);

    String rate(int count) =>
        count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

    final winCount = records.where((r) => r.diff > 0).length;
    final winRate = records.isEmpty ? 0 : (winCount / records.length) * 100;

    bool isExpanded = false;

    return StatefulBuilder(builder: (context, setInnerState) {
      return Stack(
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text("$tail 番台"),
              subtitle: Text(
                "差枚：${totalDiff >= 0 ? '+' : ''}$totalDiff / 総回転数：$totalGames G",
                style: const TextStyle(fontSize: 14),
              ),
              onExpansionChanged: (expanded) {
                setInnerState(() => isExpanded = expanded);
              },
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    Text(
                        "プレイ回数：${records.length}回  勝率：${winRate.toStringAsFixed(1)}%"),
                    const SizedBox(height: 60),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded)
            Positioned(
              bottom: 24,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MachineGraphScreen(records: records)),
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
    });
  }
}

// 特定台番号入力用ダイアログ
class _NumberInputDialog extends StatefulWidget {
  final List<String> initial;
  const _NumberInputDialog({super.key, required this.initial});

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.join(','));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("特定台番号を入力"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
            hintText: "カンマ区切りで複数番号を入力例: 12,23,45"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () {
            final list = _controller.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            Navigator.pop(context, list);
          },
          child: const Text("決定"),
        ),
      ],
    );
  }
}

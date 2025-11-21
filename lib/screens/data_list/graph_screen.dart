import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/record.dart';

class GraphScreen extends StatefulWidget {
  final List<Record> records;

  const GraphScreen({super.key, required this.records});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool showPie = false;

  @override
  Widget build(BuildContext context) {
    final records = widget.records;

    if (records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("📊 グラフ表示")),
        body: const Center(child: Text("データがありません")),
      );
    }

    // 日付順にソート（古い順）
    final sortedRecords = records.toList()
      ..sort((a, b) => DateTime.parse(a.date.replaceAll("/", "-"))
          .compareTo(DateTime.parse(b.date.replaceAll("/", "-"))));

    // 最新7件のみ取得（古い順で表示）
    final last7 = sortedRecords.length <= 7
        ? sortedRecords
        : sortedRecords.sublist(sortedRecords.length - 7);

    // 最新データ（円グラフ用）
    final latest = sortedRecords.last;

    return Scaffold(
      appBar: AppBar(title: const Text("📊 グラフ表示")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // グラフ切替ボタン
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleButton(
                    label: "📈 差枚推移",
                    selected: !showPie,
                    onTap: () => setState(() => showPie = false),
                  ),
                  const SizedBox(width: 8),
                  _buildToggleButton(
                    label: "🥧 BIG/REG比率",
                    selected: showPie,
                    onTap: () => setState(() => showPie = true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: showPie ? _buildPieChart(latest) : _buildLineChart(last7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.orange : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Record> last7) {
    final diffs = last7.map((r) => r.diff).toList();
    final minDiff = diffs.reduce((a, b) => a < b ? a : b);
    final maxDiff = diffs.reduce((a, b) => a > b ? a : b);
    final minY = (minDiff - 100).toDouble();
    final maxY = (maxDiff + 100).toDouble();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= last7.length) return const SizedBox();
                  final day = last7[index].date.split("/").last;
                  return Text(day, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(),
              bottom: BorderSide(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < last7.length; i++)
                  FlSpot(i.toDouble(), last7[i].diff.toDouble()),
              ],
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Record record) {
    final big = record.big;
    final bigDup = record.bigDup;
    final reg = record.reg;
    final regDup = record.regDup;
    final total = big + bigDup + reg + regDup;

    if (total == 0) {
      return const Center(child: Text("ボーナスデータがありません"));
    }

    final bigTotal = big + bigDup;
    final regTotal = reg + regDup;
    final bigRatio = (bigTotal / total) * 100;
    final regRatio = (regTotal / total) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("今日のボーナス内訳",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: big.toDouble(),
                  title: "BIG\n${(big / total * 100).toStringAsFixed(1)}%",
                  radius: 85,
                  titleStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.pinkAccent,
                  value: bigDup.toDouble(),
                  title: "重複BIG\n${(bigDup / total * 100).toStringAsFixed(1)}%",
                  radius: 85,
                  titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.blueAccent,
                  value: reg.toDouble(),
                  title: "REG\n${(reg / total * 100).toStringAsFixed(1)}%",
                  radius: 85,
                  titleStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.lightBlueAccent,
                  value: regDup.toDouble(),
                  title: "重複REG\n${(regDup / total * 100).toStringAsFixed(1)}%",
                  radius: 85,
                  titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "BIG系合計：${bigRatio.toStringAsFixed(1)}%   ｜   REG系合計：${regRatio.toStringAsFixed(1)}%",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

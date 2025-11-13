import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/record.dart';

class SummaryGraphScreen extends StatefulWidget {
  final List<Record> records;
  final DateTime startDate;
  final DateTime endDate;

  const SummaryGraphScreen({
    super.key,
    required this.records,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<SummaryGraphScreen> createState() => _SummaryGraphScreenState();
}

class _SummaryGraphScreenState extends State<SummaryGraphScreen> {
  bool showCumulative = false; // false = 日別, true = 累計
  bool showDiffGraph = true; // true = 差枚, false = BIG/REG比率

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    if (records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('期間グラフ')),
        body: const Center(child: Text('データがありません')),
      );
    }

    // 選択期間の日付リスト
    final dateList = <String>[];
    for (var d = widget.startDate;
        !d.isAfter(widget.endDate);
        d = d.add(const Duration(days: 1))) {
      dateList.add(DateFormat('yyyy/MM/dd').format(d));
    }

    // 日別差枚データマップ
    final diffMap = {for (var r in records) r.date: r.diff};

    // 累計 / 日別用FlSpot
    final diffSpots = <FlSpot>[];
    double cumulative = 0;
    for (var i = 0; i < dateList.length; i++) {
      final diff = diffMap[dateList[i]]?.toDouble() ?? 0.0;
      if (showCumulative) {
        cumulative += diff;
        diffSpots.add(FlSpot(i.toDouble(), cumulative));
      } else {
        diffSpots.add(FlSpot(i.toDouble(), diff));
      }
    }

    // minY/maxY自動スケーリング
    final yValues = diffSpots.map((e) => e.y).toList();
    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);
    double range = maxY - minY;
    if (range == 0) range = 1000;
    double margin = showCumulative ? range * 0.05 : range * 0.1;
    minY -= margin;
    maxY += showCumulative ? range * 0.15 : margin;
    const minMargin = 200.0;
    if ((maxY - minY) < minMargin * 2) {
      minY -= minMargin;
      maxY += minMargin;
    }

    // BIG/REG累計
    int totalBig = 0, totalBigDup = 0, totalReg = 0, totalRegDup = 0;
    for (var r in records) {
      totalBig += r.big;
      totalBigDup += r.bigDup;
      totalReg += r.reg;
      totalRegDup += r.regDup;
    }
    final totalCount = totalBig + totalBigDup + totalReg + totalRegDup;

    final pieSections = [
      PieChartSectionData(
          color: Colors.orange,
          value: totalBig.toDouble() == 0 ? 0.01 : totalBig.toDouble(),
          radius: 60,
          title: ''),
      PieChartSectionData(
          color: Colors.deepOrange,
          value: totalBigDup.toDouble() == 0 ? 0.01 : totalBigDup.toDouble(),
          radius: 60,
          title: ''),
      PieChartSectionData(
          color: Colors.blue,
          value: totalReg.toDouble() == 0 ? 0.01 : totalReg.toDouble(),
          radius: 60,
          title: ''),
      PieChartSectionData(
          color: Colors.lightBlueAccent,
          value: totalRegDup.toDouble() == 0 ? 0.01 : totalRegDup.toDouble(),
          radius: 60,
          title: ''),
    ];

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '期間グラフ (${DateFormat('MM/dd').format(widget.startDate)} ～ ${DateFormat('MM/dd').format(widget.endDate)})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 差枚 / 比率ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => showDiffGraph = true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Text("差枚グラフ"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() => showDiffGraph = false),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Text("BIG/REG比率"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showDiffGraph) ...[
              // 🔹 日別 / 累計切替ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("日別差枚"),
                    selected: !showCumulative,
                    onSelected: (_) => setState(() => showCumulative = false),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("累計差枚"),
                    selected: showCumulative,
                    onSelected: (_) => setState(() => showCumulative = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                showCumulative ? "累計差枚の推移（枚）" : "日ごとの差枚（枚）",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: diffSpots,
                        isCurved: false,
                        barWidth: 3,
                        color: showCumulative ? Colors.blueAccent : Colors.orange,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < dateList.length) {
                              return Text(
                                DateFormat('MM/dd')
                                    .format(DateFormat('yyyy/MM/dd')
                                        .parse(dateList[index])),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            interval: range / 4,
                            getTitlesWidget: (value, meta) {
                              return Text("${value.toInt()}枚",
                                  style: const TextStyle(fontSize: 10));
                            }),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ] else ...[
              // 🔹 BIG/REG円グラフ
              Text(
                "累計BIG / REG比率",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        LegendItem(
                            color: Colors.orange,
                            label:
                                "BIG ${((totalBig / totalCount) * 100).toStringAsFixed(1)}%"),
                        LegendItem(
                            color: Colors.deepOrange,
                            label:
                                "重複BIG ${((totalBigDup / totalCount) * 100).toStringAsFixed(1)}%"),
                        LegendItem(
                            color: Colors.blue,
                            label:
                                "REG ${((totalReg / totalCount) * 100).toStringAsFixed(1)}%"),
                        LegendItem(
                            color: Colors.lightBlueAccent,
                            label:
                                "重複REG ${((totalRegDup / totalCount) * 100).toStringAsFixed(1)}%"),
                      ],
                    )
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const LegendItem({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

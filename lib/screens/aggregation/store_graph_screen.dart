import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/record.dart';

enum GraphType { cumulative, ratio }

class StoreGraphScreen extends StatefulWidget {
  final List<Record> records;

  const StoreGraphScreen({super.key, required this.records});

  @override
  State<StoreGraphScreen> createState() => _StoreGraphScreenState();
}

class _StoreGraphScreenState extends State<StoreGraphScreen> {
  GraphType selectedGraph = GraphType.cumulative;

  @override
  Widget build(BuildContext context) {
    final sortedRecords = List<Record>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // ------------------------
    // ① 累計差枚折れ線
    // ------------------------
    int cumulative = 0;
    final spots = <FlSpot>[];
    final cumulativeValues = <double>[];
    for (var i = 0; i < sortedRecords.length; i++) {
      cumulative += sortedRecords[i].diff;
      final y = cumulative.toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      cumulativeValues.add(y);
    }

    // ±300 余白方式
    final maxAbs = cumulativeValues.isEmpty
        ? 0.0
        : cumulativeValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final adjustedMinY = -maxAbs - 300;
    final adjustedMaxY = maxAbs + 300;

    // ------------------------
    // ② BIG/REG比率
    // ------------------------
    final totalBig = widget.records.fold<int>(0, (s, r) => s + r.big);
    final totalBigDup = widget.records.fold<int>(0, (s, r) => s + r.bigDup);
    final totalReg = widget.records.fold<int>(0, (s, r) => s + r.reg);
    final totalRegDup = widget.records.fold<int>(0, (s, r) => s + r.regDup);

    double pct(int count) {
      final sum = totalBig + totalBigDup + totalReg + totalRegDup;
      return sum == 0 ? 0 : count / sum * 100;
    }

    final pieSections = [
      PieChartSectionData(
        value: totalBig.toDouble(),
        color: Colors.red,
        radius: 65,
        title: "BIG\n${pct(totalBig).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalBigDup.toDouble(),
        color: Colors.pink.shade200,
        radius: 65,
        title: "重複BIG\n${pct(totalBigDup).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalReg.toDouble(),
        color: Colors.blue.shade400,
        radius: 65,
        title: "REG\n${pct(totalReg).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalRegDup.toDouble(),
        color: Colors.blue.shade700,
        radius: 65,
        title: "重複REG\n${pct(totalRegDup).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("店舗別グラフ")),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // -----------------------------
          // 緑の切り替えボタン
          // -----------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGraph == GraphType.cumulative
                      ? Colors.green
                      : Colors.green.shade300,
                ),
                onPressed: () {
                  setState(() {
                    selectedGraph = GraphType.cumulative;
                  });
                },
                child:
                    const Text("累計差枚", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGraph == GraphType.ratio
                      ? Colors.green
                      : Colors.green.shade300,
                ),
                onPressed: () {
                  setState(() {
                    selectedGraph = GraphType.ratio;
                  });
                },
                child: const Text("BIG/REG比率",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Center(
              child: selectedGraph == GraphType.cumulative
                  // -------------------------
                  // ★ 折れ線グラフ
                  // -------------------------
                  ? LineChart(
                      LineChartData(
                        minY: adjustedMinY,
                        maxY: adjustedMaxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false, // 折れ線に
                            barWidth: 2,
                            color: Colors.orange,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                int idx = value.toInt();
                                if (idx < 0 || idx >= sortedRecords.length) {
                                  return const SizedBox();
                                }
                                final dd = sortedRecords[idx].date;
                                final label = dd.length >= 10
                                    ? dd.substring(8, 10)
                                    : dd;
                                return Text(label, style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1000,
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                      ),
                    )
                  // -------------------------
                  // ★ 円グラフ
                  // -------------------------
                  : Column(
                      children: [
                        SizedBox(
                          height: 260,
                          child: PieChart(
                            PieChartData(
                              sections: pieSections,
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final bigTotal = totalBig + totalBigDup;
                            final regTotal = totalReg + totalRegDup;
                            final sumTotal = bigTotal + regTotal;
                            final pctBig =
                                sumTotal == 0 ? 0 : bigTotal / sumTotal * 100;
                            final pctReg =
                                sumTotal == 0 ? 0 : regTotal / sumTotal * 100;
                            return Text(
                              "BIG $bigTotal回 ${pctBig.toStringAsFixed(0)}% : "
                              "REG $regTotal回 ${pctReg.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

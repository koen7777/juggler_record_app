// lib/screens/data_list/graph_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/record.dart';

class GraphScreen extends StatelessWidget {
  final List<Record> records;

  const GraphScreen({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    // 最新7件だけ取り出して逆順（古い→新しい）
    final last7 = records.take(7).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("📈 1週間の差枚推移")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: last7.isEmpty
            ? const Center(child: Text("データがありません"))
            : SizedBox(
                height: 300, // 高さ固定で描画確保
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 100,
                      verticalInterval: 1,
                    ),
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
                            return Text(
                              last7[index].date.split("/").last,
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
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
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(),
                        bottom: BorderSide(),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

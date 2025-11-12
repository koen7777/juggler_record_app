import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/record.dart';

class SummaryGraphScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('期間差枚グラフ')),
        body: const Center(child: Text('データがありません')),
      );
    }

    // 日付文字列をキーにした Map を作成
    final recordMap = {for (var r in records) r.date: r.diff};

    // startDate 〜 endDate の日付リストを作る
    final dateList = <String>[];
    for (var d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))) {
      dateList.add(DateFormat('yyyy/MM/dd').format(d));
    }

    // FlSpot 作成（日付がない場合は 0）
    final spots = <FlSpot>[];
    for (var i = 0; i < dateList.length; i++) {
      final diff = recordMap[dateList[i]]?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), diff));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('選択期間差枚グラフ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "日ごとの差枚",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3,
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
                          final index = value.toInt();
                          if (index >= 0 && index < dateList.length) {
                            return Text(
                              DateFormat('MM-dd').format(
                                  DateFormat('yyyy/MM/dd')
                                      .parse(dateList[index])),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1000),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

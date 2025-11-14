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
  bool showCumulative = false;
  bool showDiffGraph = true;

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    if (records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('期間グラフ')),
        body: const Center(child: Text('データがありません')),
      );
    }

    //---------------------------------
    // ■ 日付リスト生成
    //---------------------------------
    final dateList = <String>[];
    for (var d = widget.startDate;
        !d.isAfter(widget.endDate);
        d = d.add(const Duration(days: 1))) {
      dateList.add(DateFormat('yyyy/MM/dd').format(d));
    }

    //---------------------------------
    // ■ 差枚データ
    //---------------------------------
    final diffMap = {for (var r in records) r.date: r.diff};

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

    // minY/maxY
    final yValues = diffSpots.map((e) => e.y).toList();
    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);
    double range = maxY - minY;
    if (range == 0) range = 1000;
    double margin = showCumulative ? range * 0.05 : range * 0.1;
    minY -= margin;
    maxY += showCumulative ? range * 0.1 : margin;

    //----- 期間累計の BIG/REG -----
    int totalBig = 0, totalBigDup = 0, totalReg = 0, totalRegDup = 0;
    for (var r in records) {
      totalBig += r.big;
      totalBigDup += r.bigDup;
      totalReg += r.reg;
      totalRegDup += r.regDup;
    }
    final totalCount =
        totalBig + totalBigDup + totalReg + totalRegDup;

    // パーセンテージ
    double pct(int v) => totalCount == 0 ? 0 : v / totalCount * 100;

    // ★ 円グラフカラー
    final bigColor = Colors.red;            // BIG → 赤
    final bigDupColor = Colors.pink.shade200; // 重複BIG → 薄いピンク
    final regColor = Colors.blue.shade400;  
    final regDupColor = Colors.blue.shade700;

    //---------------------------------
    //  ■ 円グラフ sections（名称修正済み）
    //---------------------------------
    final pieSections = [
      PieChartSectionData(
        value: totalBig.toDouble(),
        color: bigColor,
        radius: 65,
        title: "BIG\n${pct(totalBig).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalBigDup.toDouble(),
        color: bigDupColor,
        radius: 65,
        title: "重複BIG\n${pct(totalBigDup).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalReg.toDouble(),
        color: regColor,
        radius: 65,
        title: "REG\n${pct(totalReg).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      PieChartSectionData(
        value: totalRegDup.toDouble(),
        color: regDupColor,
        radius: 65,
        title: "重複REG\n${pct(totalRegDup).toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ];

    //---------------------------------
    //         画面全体
    //---------------------------------
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '期間グラフ (${DateFormat('MM/dd').format(widget.startDate)} ～ ${DateFormat('MM/dd').format(widget.endDate)})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //---------------------
            // 差枚/比率 切り替え
            //---------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () => setState(() => showDiffGraph = true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            showDiffGraph ? Colors.green : Colors.grey),
                    child: const Text("差枚グラフ")),
                const SizedBox(width: 12),
                ElevatedButton(
                    onPressed: () => setState(() => showDiffGraph = false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !showDiffGraph ? Colors.green : Colors.grey),
                    child: const Text("BIG/REG比率")),
              ],
            ),
            const SizedBox(height: 16),

            //-------------------------------------------------------------
            // ① 差枚グラフ
            //-------------------------------------------------------------
            if (showDiffGraph) ...[
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
                showCumulative ? "累計差枚の推移" : "日ごとの差枚",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

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
                        color: showCumulative
                            ? Colors.blueAccent
                            : Colors.orange,
                        dotData: FlDotData(show: true),
                      )
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: range / 4,
                          getTitlesWidget: (value, _) => Text(
                            "${value.toInt()}枚",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dateList.length) {
                              return Text(
                                DateFormat("MM/dd").format(DateFormat("yyyy/MM/dd")
                                    .parse(dateList[idx])),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),

              //-------------------------------------------------------------
              // ② 円グラフ（BIG/REG）
              //-------------------------------------------------------------
            ] else ...[
              const SizedBox(height: 10),
              const Text(
                "累計BIG / REG比率",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // PieChart の高さを固定して下に合計表示を可能に
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // BIG合計/REG合計 表示
                  Builder(
                    builder: (context) {
                      final bigTotal = totalBig + totalBigDup;
                      final regTotal = totalReg + totalRegDup;
                      final sumTotal = bigTotal + regTotal;
                      double pctBig = sumTotal == 0 ? 0 : bigTotal / sumTotal * 100;
                      double pctReg = sumTotal == 0 ? 0 : regTotal / sumTotal * 100;

                      return Text(
                        "BIG $bigTotal回 ${pctBig.toStringAsFixed(0)}% : "
                        "REG $regTotal回 ${pctReg.toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

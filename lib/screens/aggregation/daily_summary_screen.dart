// lib/screens/aggregation/daily_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final DBHelperWeb _dbHelper = DBHelperWeb();

  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<Record> _allRecords = [];
  List<Record> _displayRecords = [];

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('yyyy/MM/dd').format(_selectedStartDate);
    _endDateController.text = DateFormat('yyyy/MM/dd').format(_selectedEndDate);
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _dbHelper.getRecords();
    setState(() {
      _allRecords = records;
      _filterRecords();
    });
  }

  void _filterRecords() {
    setState(() {
      _displayRecords = _allRecords.where((r) {
        final recordDate = DateFormat('yyyy/MM/dd').parse(r.date);
        return !recordDate.isBefore(_selectedStartDate) &&
               !recordDate.isAfter(_selectedEndDate);
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final pickedStart = await showDatePicker(
      context: context,
      locale: const Locale('ja'),
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      locale: const Locale('ja'),
      initialDate: pickedStart,
      firstDate: pickedStart,
      lastDate: DateTime(2100),
    );
    if (pickedEnd == null) return;

    setState(() {
      _selectedStartDate = pickedStart;
      _selectedEndDate = pickedEnd;
      _startDateController.text = DateFormat('yyyy/MM/dd').format(pickedStart);
      _endDateController.text = DateFormat('yyyy/MM/dd').format(pickedEnd);
      _filterRecords();
    });
  }

  void _setQuickRange(Duration range) {
    final now = DateTime.now();
    setState(() {
      _selectedEndDate = now;
      _selectedStartDate = now.subtract(range);
      _startDateController.text = DateFormat('yyyy/MM/dd').format(_selectedStartDate);
      _endDateController.text = DateFormat('yyyy/MM/dd').format(_selectedEndDate);
      _filterRecords();
    });
  }

  Record _computeSummary(List<Record> records) {
    int totalRotation = 0, diff = 0;
    int big = 0, reg = 0, bigDup = 0, regDup = 0, cherry = 0, grape = 0;

    for (var r in records) {
      totalRotation += r.totalRotation;
      diff += r.diff;
      big += r.big;
      reg += r.reg;
      bigDup += r.bigDup;
      regDup += r.regDup;
      cherry += r.cherry;
      grape += r.grape;
    }

    return Record(
      date:
          "${DateFormat('yyyy/MM/dd').format(_selectedStartDate)} ～ ${DateFormat('yyyy/MM/dd').format(_selectedEndDate)}",
      machine: "",
      shop: "",
      number: "",
      totalRotation: totalRotation,
      diff: diff,
      big: big,
      reg: reg,
      bigDup: bigDup,
      regDup: regDup,
      cherry: cherry,
      grape: grape,
    );
  }

  Widget _summaryCard(Record record) {
    final totalRotation = record.totalRotation;

    final bigRate = record.big == 0 ? "-" : "1/${(totalRotation / record.big).toStringAsFixed(2)}";
    final regRate = record.reg == 0 ? "-" : "1/${(totalRotation / record.reg).toStringAsFixed(2)}";
    final bigDupRate = record.bigDup == 0 ? "-" : "1/${(totalRotation / record.bigDup).toStringAsFixed(2)}";
    final regDupRate = record.regDup == 0 ? "-" : "1/${(totalRotation / record.regDup).toStringAsFixed(2)}";

    final totalBonus = record.big + record.reg + record.bigDup + record.regDup;
    final totalBonusRate = totalBonus == 0 ? "-" : "1/${(totalRotation / totalBonus).toStringAsFixed(2)}";

    final bigTotal = record.big + record.bigDup;
    final bigTotalRate = bigTotal == 0 ? "-" : "1/${(totalRotation / bigTotal).toStringAsFixed(2)}";

    final regTotal = record.reg + record.regDup;
    final regTotalRate = regTotal == 0 ? "-" : "1/${(totalRotation / regTotal).toStringAsFixed(2)}";

    final cherryRate = record.cherry == 0 ? "-" : "1/${(totalRotation / record.cherry).toStringAsFixed(2)}";
    final grapeRate = record.grape == 0 ? "-" : "1/${(totalRotation / record.grape).toStringAsFixed(2)}";

    final payoutValue =
        totalRotation == 0 ? 0.0 : ((record.diff / (totalRotation * 3)) * 100 + 100);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📊 選択期間合計 (${record.date})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("差枚: ${record.diff >= 0 ? '+' : ''}${record.diff}枚  総回転: $totalRotation G"),
            Text("ペイアウト率: ${payoutValue.toStringAsFixed(1)}%"),
            const SizedBox(height: 4),
            Text("BIG ${record.big}回 ($bigRate)  REG ${record.reg}回 ($regRate)"),
            Text("重複BIG ${record.bigDup}回 ($bigDupRate)  重複REG ${record.regDup}回 ($regDupRate)"),
            Text("ボーナス合計: $totalBonus回  合算確率: $totalBonusRate"),
            Text("BIG合計: $bigTotal回  確率: $bigTotalRate  REG合計: $regTotal回  確率: $regTotalRate"),
            Text("チェリー ${record.cherry}回 ($cherryRate)  ぶどう ${record.grape}回 ($grapeRate)"),
          ],
        ),
      ),
    );
  }

  Widget _recordExpansionTile(Record record) {
    final totalRotation = record.totalRotation;
    final payoutValue =
        totalRotation == 0 ? 0.0 : ((record.diff / (totalRotation * 3)) * 100 + 100);

    final totalBonus = record.big + record.reg + record.bigDup + record.regDup;
    final totalBonusRate = totalBonus == 0 ? "-" : "1/${(totalRotation / totalBonus).toStringAsFixed(2)}";

    final bigTotal = record.big + record.bigDup;
    final bigTotalRate = bigTotal == 0 ? "-" : "1/${(totalRotation / bigTotal).toStringAsFixed(2)}";

    final regTotal = record.reg + record.regDup;
    final regTotalRate = regTotal == 0 ? "-" : "1/${(totalRotation / regTotal).toStringAsFixed(2)}";

    final bigRate = record.big == 0 ? "-" : "1/${(totalRotation / record.big).toStringAsFixed(2)}";
    final regRate = record.reg == 0 ? "-" : "1/${(totalRotation / record.reg).toStringAsFixed(2)}";
    final bigDupRate = record.bigDup == 0 ? "-" : "1/${(totalRotation / record.bigDup).toStringAsFixed(2)}";
    final regDupRate = record.regDup == 0 ? "-" : "1/${(totalRotation / record.regDup).toStringAsFixed(2)}";

    final cherryRate = record.cherry == 0 ? "-" : "1/${(totalRotation / record.cherry).toStringAsFixed(2)}";
    final grapeRate = record.grape == 0 ? "-" : "1/${(totalRotation / record.grape).toStringAsFixed(2)}";

    return ExpansionTile(
      title: Text("${record.date}  差枚: ${record.diff >= 0 ? '+' : ''}${record.diff}枚  総回転: ${record.totalRotation}G"),
      subtitle: Text(
          "ペイアウト率: ${payoutValue.toStringAsFixed(1)}%  ボーナス合計: $totalBonus回  合算確率: $totalBonusRate"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("BIG ${record.big}回 ($bigRate)  REG ${record.reg}回 ($regRate)"),
              Text("重複BIG ${record.bigDup}回 ($bigDupRate)  重複REG ${record.regDup}回 ($regDupRate)"),
              Text("BIG合計: $bigTotal回  確率: $bigTotalRate  REG合計: $regTotal回  確率: $regTotalRate"),
              Text("チェリー ${record.cherry}回 ($cherryRate)  ぶどう ${record.grape}回 ($grapeRate)"),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryRecord = _computeSummary(_displayRecords);
    return Scaffold(
      appBar: AppBar(title: const Text("日別集計")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: '開始日', border: OutlineInputBorder()),
                    onTap: _pickDateRange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: '終了日', border: OutlineInputBorder()),
                    onTap: _pickDateRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _setQuickRange(const Duration(days: 2)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("直近3日"),
                ),
                ElevatedButton(
                  onPressed: () => _setQuickRange(const Duration(days: 6)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("1週間"),
                ),
                ElevatedButton(
                  onPressed: () => _setQuickRange(const Duration(days: 29)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("1か月"),
                ),
              ],
            ),
            _summaryCard(summaryRecord),
            const SizedBox(height: 8),
            ..._displayRecords.map(_recordExpansionTile).toList(),
          ],
        ),
      ),
    );
  }
}

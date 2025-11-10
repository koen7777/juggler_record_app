// lib/screens/aggregation/daily_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import '../data_list/graph_screen.dart'; // GraphScreen を正しい場所からインポート


class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final DBHelperWeb _dbHelper = DBHelperWeb();

  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  final TextEditingController _dateRangeController = TextEditingController();

  List<Record> _allRecords = [];
  List<Record> _displayRecords = [];

  @override
  void initState() {
    super.initState();
    _updateDateRangeText();
    _loadRecords();
  }

  void _updateDateRangeText() {
    _dateRangeController.text =
        "${DateFormat('yyyy/MM/dd').format(_selectedStartDate)} ～ ${DateFormat('yyyy/MM/dd').format(_selectedEndDate)}";
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
    final newRange = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RangeCalendarPicker(
          initialStart: _selectedStartDate,
          initialEnd: _selectedEndDate,
        ),
      ),
    );

    if (newRange is List<DateTime> && newRange.length == 2) {
      setState(() {
        _selectedStartDate = newRange[0];
        _selectedEndDate = newRange[1];
        _updateDateRangeText();
        _filterRecords();
      });
    }
  }

  void _setQuickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _selectedEndDate = now;
      _selectedStartDate = now.subtract(Duration(days: days - 1));
      _updateDateRangeText();
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
    final bigRate =
        record.big == 0 ? "-" : "1/${(totalRotation / record.big).toStringAsFixed(2)}";
    final regRate =
        record.reg == 0 ? "-" : "1/${(totalRotation / record.reg).toStringAsFixed(2)}";
    final bigDupRate =
        record.bigDup == 0 ? "-" : "1/${(totalRotation / record.bigDup).toStringAsFixed(2)}";
    final regDupRate =
        record.regDup == 0 ? "-" : "1/${(totalRotation / record.regDup).toStringAsFixed(2)}";
    final totalBonus = record.big + record.reg + record.bigDup + record.regDup;
    final totalBonusRate =
        totalBonus == 0 ? "-" : "1/${(totalRotation / totalBonus).toStringAsFixed(2)}";
    final bigTotal = record.big + record.bigDup;
    final bigTotalRate =
        bigTotal == 0 ? "-" : "1/${(totalRotation / bigTotal).toStringAsFixed(2)}";
    final regTotal = record.reg + record.regDup;
    final regTotalRate =
        regTotal == 0 ? "-" : "1/${(totalRotation / regTotal).toStringAsFixed(2)}";
    final cherryRate =
        record.cherry == 0 ? "-" : "1/${(totalRotation / record.cherry).toStringAsFixed(2)}";
    final grapeRate =
        record.grape == 0 ? "-" : "1/${(totalRotation / record.grape).toStringAsFixed(2)}";
    final payoutValue =
        totalRotation == 0 ? 0.0 : ((record.diff / (totalRotation * 3)) * 100 + 100);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("📊 選択期間合計 (${record.date})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                "差枚: ${record.diff >= 0 ? '+' : ''}${record.diff}枚  総回転: $totalRotation G"),
            Text("ペイアウト率: ${payoutValue.toStringAsFixed(1)}%"),
            const SizedBox(height: 4),
            Text("BIG ${record.big}回 ($bigRate)  REG ${record.reg}回 ($regRate)"),
            Text(
                "重複BIG ${record.bigDup}回 ($bigDupRate)  重複REG ${record.regDup}回 ($regDupRate)"),
            Text("ボーナス合計: $totalBonus回  合算確率: $totalBonusRate"),
            Text(
                "BIG合計: $bigTotal回  確率: $bigTotalRate  REG合計: $regTotal回  確率: $regTotalRate"),
            Text("チェリー ${record.cherry}回 ($cherryRate)  ぶどう ${record.grape}回 ($grapeRate)"),
            const SizedBox(height: 12),
            // ← ここに円形グラフボタンを追加
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            GraphScreen(records: _displayRecords)),
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
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.show_chart, color: Colors.white),
                      SizedBox(height: 2),
                      Text("グラフ",
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            // 期間選択
            TextFormField(
              controller: _dateRangeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '期間選択',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDateRange,
            ),
            const SizedBox(height: 8),
            // プリセット範囲（緑ボタン）
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _setQuickRange(3),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("3日間"),
                ),
                ElevatedButton(
                  onPressed: () => _setQuickRange(7),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("1週間"),
                ),
                ElevatedButton(
                  onPressed: () => _setQuickRange(30),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("1か月"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 選択期間合計
            _summaryCard(summaryRecord),
            const SizedBox(height: 16),
            // 日別データ一覧（折りたたみ）
            const Text(
              "日別データ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._displayRecords.map((r) {
              final totalRotation = r.totalRotation;
              final bigRate = r.big == 0
                  ? "-"
                  : "1/${(totalRotation / r.big).toStringAsFixed(2)}";
              final regRate = r.reg == 0
                  ? "-"
                  : "1/${(totalRotation / r.reg).toStringAsFixed(2)}";
              final bigDupRate = r.bigDup == 0
                  ? "-"
                  : "1/${(totalRotation / r.bigDup).toStringAsFixed(2)}";
              final regDupRate = r.regDup == 0
                  ? "-"
                  : "1/${(totalRotation / r.regDup).toStringAsFixed(2)}";

              final totalBonus = r.big + r.reg + r.bigDup + r.regDup;
              final totalBonusRate = totalBonus == 0
                  ? "-"
                  : "1/${(totalRotation / totalBonus).toStringAsFixed(2)}";

              final bigTotal = r.big + r.bigDup;
              final bigTotalRate = bigTotal == 0
                  ? "-"
                  : "1/${(totalRotation / bigTotal).toStringAsFixed(2)}";

              final regTotal = r.reg + r.regDup;
              final regTotalRate = regTotal == 0
                  ? "-"
                  : "1/${(totalRotation / regTotal).toStringAsFixed(2)}";

              final cherryRate = r.cherry == 0
                  ? "-"
                  : "1/${(totalRotation / r.cherry).toStringAsFixed(2)}";
              final grapeRate = r.grape == 0
                  ? "-"
                  : "1/${(totalRotation / r.grape).toStringAsFixed(2)}";

              final payoutValue = totalRotation == 0
                  ? 0.0
                  : ((r.diff / (totalRotation * 3)) * 100 + 100);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Text(
                      "${r.date} (${r.machine})  差枚: ${r.diff >= 0 ? '+' : ''}${r.diff}枚"),
                  subtitle: Text(
                      "総回転: ${totalRotation}G  ペイアウト率: ${payoutValue.toStringAsFixed(1)}%"),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Text("BIG: ${r.big}回 ($bigRate)  REG: ${r.reg}回 ($regRate)"),
                    Text(
                        "重複BIG: ${r.bigDup}回 ($bigDupRate)  重複REG: ${r.regDup}回 ($regDupRate)"),
                    Text(
                        "ボーナス合計: ${totalBonus}回  合算確率: $totalBonusRate"),
                    Text(
                        "BIG合計: ${bigTotal}回  合算確率: ${bigTotalRate}  REG合計: ${regTotal}回  合算確率: ${regTotalRate}"),
                    Text(
                        "チェリー: ${r.cherry}回 ($cherryRate)  ぶどう: ${r.grape}回 ($grapeRate)"),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// RangeCalendarPicker：カレンダー範囲選択画面（自由選択可能）
class RangeCalendarPicker extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;

  const RangeCalendarPicker({
    super.key,
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<RangeCalendarPicker> createState() => _RangeCalendarPickerState();
}

class _RangeCalendarPickerState extends State<RangeCalendarPicker> {
  late DateTime _focusedDay;
  DateTime? _startDay;
  DateTime? _endDay;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialStart;
    _startDay = widget.initialStart;
    _endDay = widget.initialEnd;
    _rangeSelectionMode = RangeSelectionMode.toggledOn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('期間選択')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ja_JP',
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            rangeStartDay: _startDay,
            rangeEndDay: _endDay,
            rangeSelectionMode: _rangeSelectionMode,
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;

                if (_rangeSelectionMode == RangeSelectionMode.toggledOff) {
                  _startDay = selectedDay;
                  _endDay = null;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                } else if (_startDay != null && _endDay == null) {
                  if (selectedDay.isBefore(_startDay!)) {
                    _endDay = _startDay;
                    _startDay = selectedDay;
                  } else {
                    _endDay = selectedDay;
                  }
                  _rangeSelectionMode = RangeSelectionMode.toggledOff;
                } else {
                  _startDay = selectedDay;
                  _endDay = null;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_startDay != null && _endDay != null) {
                Navigator.pop(context, [_startDay!, _endDay!]);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('期間を選択してください')),
                );
              }
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }
}

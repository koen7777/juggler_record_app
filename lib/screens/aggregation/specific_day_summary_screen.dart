import 'package:flutter/material.dart';
import '../../database/db_helper_web.dart';
import '../../models/record.dart';
import '../aggregation/machine_graph_screen.dart';

enum FilterType { DigitDay, DoubleDigit, MonthDouble }

class SpecificDaySummaryScreen extends StatefulWidget {
  const SpecificDaySummaryScreen({super.key});

  @override
  State<SpecificDaySummaryScreen> createState() =>
      _SpecificDaySummaryScreenState();
}

class _SpecificDaySummaryScreenState extends State<SpecificDaySummaryScreen> {
  final DBHelperWeb _db = DBHelperWeb();

  List<Record> allRecords = [];
  List<Record> filtered = [];
  bool isLoaded = false;

  // 集計用
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

  // フィルター状態
  FilterType filterType = FilterType.DigitDay;
  int filterDigit = 1; // ◯の日用
  int selectedDoubleDigit = 11; // ゾロ目の日用（11 or 22）
  int selectedMonthZoro = 1; // 月ゾロ用
  String? selectedShop; // 店舗選択

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getRecords();
    allRecords = list;
    _applyFilter();
    setState(() => isLoaded = true);
  }

  void _applyFilter() {
    filtered = allRecords.where((r) {
      if (selectedShop != null && selectedShop!.isNotEmpty) {
        if (r.shop != selectedShop) return false;
      }
      switch (filterType) {
        case FilterType.DigitDay:
          if (r.date.length < 1) return false;
          return r.date.endsWith(filterDigit.toString());
        case FilterType.DoubleDigit:
          if (r.date.length < 2) return false;
          final day = int.tryParse(r.date.substring(r.date.length - 2)) ?? 0;
          return day == selectedDoubleDigit;
        case FilterType.MonthDouble:
          final parts = r.date.split('/');
          if (parts.length < 3) return false;
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          if (month == null || day == null) return false;
          return month == day && month == selectedMonthZoro;
      }
    }).toList();

    totalGames = filtered.fold(0, (sum, r) => sum + r.totalRotation);
    totalDiff = filtered.fold(0, (sum, r) => sum + r.diff);
    totalBig = filtered.fold(0, (sum, r) => sum + r.big);
    totalBigDup = filtered.fold(0, (sum, r) => sum + r.bigDup);
    totalReg = filtered.fold(0, (sum, r) => sum + r.reg);
    totalRegDup = filtered.fold(0, (sum, r) => sum + r.regDup);
    totalCherry = filtered.fold(0, (sum, r) => sum + r.cherry);
    totalGrape = filtered.fold(0, (sum, r) => sum + r.grape);
    totalBonus = totalBig + totalBigDup + totalReg + totalRegDup;
    bigTotal = totalBig + totalBigDup;
    regTotal = totalReg + totalRegDup;
    payout = totalGames == 0 ? 0 : ((totalDiff / (totalGames * 3)) * 100 + 100);
    playCount = filtered.length;
    final winCount = filtered.where((r) => r.diff > 0).length;
    winRate = playCount == 0 ? 0 : (winCount / playCount) * 100;
  }

  String rate(int count) =>
      count == 0 ? "-" : "1/${(totalGames / count).toStringAsFixed(0)}";

  void _changeDigit() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _DigitSelectDialog(initial: filterDigit),
    );
    if (result != null) {
      filterDigit = result;
      setState(() {
        filterType = FilterType.DigitDay;
        _applyFilter();
      });
    }
  }

  void _changeDoubleDigit() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _DoubleDigitSelectDialog(initial: selectedDoubleDigit),
    );
    if (result != null) {
      selectedDoubleDigit = result;
      setState(() {
        filterType = FilterType.DoubleDigit;
        _applyFilter();
      });
    }
  }

  void _changeMonthZoro() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _MonthZoroSelectDialog(initial: selectedMonthZoro),
    );
    if (result != null) {
      selectedMonthZoro = result;
      setState(() {
        filterType = FilterType.MonthDouble;
        _applyFilter();
      });
    }
  }

  void _changeShop() async {
    final shops = allRecords.map((r) => r.shop).toSet().toList();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ShopSelectDialog(
        shops: shops,
        initial: selectedShop,
      ),
    );
    if (result != null) {
      selectedShop = result;
      setState(() => _applyFilter());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_filterTitle()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _filterButton("◯の日", _changeDigit),
                const SizedBox(width: 6),
                _filterButton("ゾロ目の日", _changeDoubleDigit),
                const SizedBox(width: 6),
                _filterButton("月ゾロの日", _changeMonthZoro),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _changeShop,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.store, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: !isLoaded
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(child: Text("該当データがありません"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 16),
                    ...filtered.map((r) => _itemCard(r)),
                  ],
                ),
    );
  }

  String _filterTitle() {
    String title = "";
    switch (filterType) {
      case FilterType.DigitDay:
        title = "${filterDigit}のつく日";
        break;
      case FilterType.DoubleDigit:
        title = "ゾロ目の日: ${selectedDoubleDigit}日";
        break;
      case FilterType.MonthDouble:
        title = "月ゾロの日: ${selectedMonthZoro}月${selectedMonthZoro}日";
        break;
    }
    if (selectedShop != null && selectedShop!.isNotEmpty) {
      title = "$selectedShop / $title";
    }
    return "$title 集計";
  }

  Widget _filterButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          "集計結果",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "差枚：${totalDiff >= 0 ? '+' : ''}$totalDiff枚 / 総回転数：$totalGames G",
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "差枚",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${totalDiff >= 0 ? '+' : ''}$totalDiff枚",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: totalDiff < 0 ? Colors.red : Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text("総回転数：$totalGames G"),
                  Text(
                    "ペイアウト：${payout.toStringAsFixed(1)}%",
                    style: TextStyle(color: payout < 100 ? Colors.red : Colors.black),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text("BIG $totalBig回 (${rate(totalBig)})   REG $totalReg回 (${rate(totalReg)})"),
                  const SizedBox(height: 6),
                  Text("重複BIG $totalBigDup回 (${rate(totalBigDup)})   重複REG $totalRegDup回 (${rate(totalRegDup)})"),
                  const SizedBox(height: 6),
                  Text("チェリー $totalCherry回 (${rate(totalCherry)})   ぶどう $totalGrape回 (${rate(totalGrape)})"),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text("ボーナス合計: $totalBonus回  合算: ${rate(totalBonus)}"),
                  Text("BIG合計: $bigTotal回 (${rate(bigTotal)})   REG合計: $regTotal回 (${rate(regTotal)})"),
                  const SizedBox(height: 10),
                  Text(
                    "プレイ回数：$playCount回  勝率：${winRate.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MachineGraphScreen(records: filtered),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
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
          ),
        ],
      ),
    );
  }

  Widget _itemCard(Record r) {
    final payout = r.totalRotation == 0
        ? 0.0
        : ((r.diff / (r.totalRotation * 3)) * 100 + 100);

    return Card(
      child: ListTile(
        title: Text("${r.date}  ${r.machine}"),
        subtitle: Text("${r.totalRotation}G / 差枚 ${r.diff}"),
        trailing: Text(
          "${payout.toStringAsFixed(1)}%",
          style: TextStyle(color: payout < 100 ? Colors.red : Colors.black),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MachineGraphScreen(records: [r]),
            ),
          );
        },
      ),
    );
  }
}

// ◯の日選択ダイアログ
class _DigitSelectDialog extends StatefulWidget {
  final int initial;
  const _DigitSelectDialog({required this.initial});

  @override
  State<_DigitSelectDialog> createState() => _DigitSelectDialogState();
}

class _DigitSelectDialogState extends State<_DigitSelectDialog> {
  late int _digit;

  @override
  void initState() {
    super.initState();
    _digit = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("何のつく日？"),
      content: DropdownButton<int>(
        value: _digit,
        items: List.generate(
          9,
          (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1} のつく日")),
        ),
        onChanged: (v) => setState(() => _digit = v!),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
        ElevatedButton(onPressed: () => Navigator.pop(context, _digit), child: const Text("決定")),
      ],
    );
  }
}

// ゾロ目の日選択ダイアログ
class _DoubleDigitSelectDialog extends StatefulWidget {
  final int initial;
  const _DoubleDigitSelectDialog({required this.initial});

  @override
  State<_DoubleDigitSelectDialog> createState() => _DoubleDigitSelectDialogState();
}

class _DoubleDigitSelectDialogState extends State<_DoubleDigitSelectDialog> {
  late int _digit;

  @override
  void initState() {
    super.initState();
    _digit = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ゾロ目の日を選択"),
      content: DropdownButton<int>(
        value: _digit,
        items: [11, 22].map((d) => DropdownMenuItem(value: d, child: Text("$d日"))).toList(),
        onChanged: (v) => setState(() => _digit = v!),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
        ElevatedButton(onPressed: () => Navigator.pop(context, _digit), child: const Text("決定")),
      ],
    );
  }
}

// 月ゾロ選択ダイアログ
class _MonthZoroSelectDialog extends StatefulWidget {
  final int initial;
  const _MonthZoroSelectDialog({required this.initial});

  @override
  State<_MonthZoroSelectDialog> createState() => _MonthZoroSelectDialogState();
}

class _MonthZoroSelectDialogState extends State<_MonthZoroSelectDialog> {
  late int _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("月ゾロの日を選択"),
      content: DropdownButton<int>(
        value: _month,
        items: List.generate(
          12,
          (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1}月${i + 1}日")),
        ),
        onChanged: (v) => setState(() => _month = v!),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
        ElevatedButton(onPressed: () => Navigator.pop(context, _month), child: const Text("決定")),
      ],
    );
  }
}

// 店舗選択ダイアログ
class _ShopSelectDialog extends StatefulWidget {
  final List<String> shops;
  final String? initial;
  const _ShopSelectDialog({required this.shops, this.initial});

  @override
  State<_ShopSelectDialog> createState() => _ShopSelectDialogState();
}

class _ShopSelectDialogState extends State<_ShopSelectDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("店舗を選択"),
      content: DropdownButton<String>(
        value: _selected,
        items: widget.shops
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _selected = v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
        ElevatedButton(onPressed: () => Navigator.pop(context, _selected), child: const Text("決定")),
      ],
    );
  }
}

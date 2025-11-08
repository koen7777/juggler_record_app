// lib/screens/add_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../database/db_helper_web.dart';

class AddRecordScreen extends StatefulWidget {
  final Record? record;
  final int? recordIndex;

  const AddRecordScreen({super.key, this.record, this.recordIndex});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final DBHelperWeb _dbHelper = DBHelperWeb();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<String> _machines = [
    'アイムジャグラー', 'ファンキージャグラー', 'マイジャグラー',
    'GOGOジャグラー', 'ジャグラーガールズ', 'ハッピージャグラー',
    'ミスタージャグラー', 'ウルトラミラクルジャグラー', 'その他',
  ];
  String? _selectedMachine;

  List<String> _shops = [];
  String? _selectedShop;
  bool _shopTapped = false;

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _rotationController = TextEditingController();
  final TextEditingController _diffController = TextEditingController();
  final TextEditingController _bigController = TextEditingController();
  final TextEditingController _regController = TextEditingController();
  final TextEditingController _dupBigController = TextEditingController();
  final TextEditingController _dupRegController = TextEditingController();
  final TextEditingController _cherryController = TextEditingController();
  final TextEditingController _grapeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy/MM/dd', 'ja').format(_selectedDate);
    _loadShops();

    if (widget.record != null) {
      final r = widget.record!;
      _selectedDate = DateFormat('yyyy/MM/dd').parse(r.date);
      _dateController.text = r.date;
      _selectedMachine = r.machine;
      _selectedShop = r.shop;
      _numberController.text = r.number;
      _rotationController.text = r.totalRotation.toString();
      _diffController.text = r.diff.toString();
      _bigController.text = r.big.toString();
      _regController.text = r.reg.toString();
      _dupBigController.text = r.bigDup.toString();
      _dupRegController.text = r.regDup.toString();
      _cherryController.text = r.cherry.toString();
      _grapeController.text = r.grape.toString();
    }
  }

  Future<void> _loadShops() async {
    final shops = await _dbHelper.getShops();
    setState(() => _shops = shops);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ja'),
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy/MM/dd', 'ja').format(picked);
      });
    }
  }

  Widget _buildMachineDropdown() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(
      value: _selectedMachine,
      items: _machines.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (v) => setState(() => _selectedMachine = v),
      decoration: const InputDecoration(labelText: '機種名', border: OutlineInputBorder()),
      validator: (v) => v == null ? '必須項目です' : null,
    ),
  );

  Widget _buildShopDropdown() {
    if (_shops.isEmpty) return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text('※登録済み店舗がありません。', style: TextStyle(color: Colors.red)),
    );

    return GestureDetector(
      onTap: () => setState(() => _shopTapped = true),
      child: AbsorbPointer(
        absorbing: !_shopTapped,
        child: DropdownButtonFormField<String>(
          value: _shopTapped ? _selectedShop : null,
          hint: const Text('タップして店舗を選択'),
          items: _shops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedShop = v),
          decoration: const InputDecoration(labelText: '店舗名', border: OutlineInputBorder()),
          validator: (v) => v == null || v.isEmpty ? '必須項目です' : null,
        ),
      ),
    );
  }

  Widget _buildNumField(
    String label,
    TextEditingController c, {
    bool required = true,
    bool allowNegative = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          keyboardType: allowNegative
              ? const TextInputType.numberWithOptions(signed: true)
              : TextInputType.number,
          inputFormatters: allowNegative
              ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (!required) return null;
            if (v == null || v.isEmpty) return '必須項目です';
            return null;
          },
        ),
      );

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final record = Record(
      date: _dateController.text,
      machine: _selectedMachine!,
      shop: _selectedShop!,
      number: _numberController.text,
      totalRotation: int.tryParse(_rotationController.text) ?? 0,
      diff: int.tryParse(_diffController.text) ?? 0,
      big: int.tryParse(_bigController.text) ?? 0,
      reg: int.tryParse(_regController.text) ?? 0,
      bigDup: int.tryParse(_dupBigController.text) ?? 0,
      regDup: int.tryParse(_dupRegController.text) ?? 0,
      cherry: int.tryParse(_cherryController.text) ?? 0,
      grape: int.tryParse(_grapeController.text) ?? 0,
    );

    if (widget.recordIndex != null) {
      await _dbHelper.updateRecord(widget.recordIndex!, record);
    } else {
      await _dbHelper.insertRecord(record);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('データを保存しました')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
        absorbing: _saving,
        child: Scaffold(
          appBar: AppBar(title: Text(widget.recordIndex != null ? 'データ編集' : 'データ入力')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: '日付', border: OutlineInputBorder()),
                      onTap: _pickDate,
                    ),
                  ),
                  _buildMachineDropdown(),
                  _buildShopDropdown(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(labelText: '台番号（任意）', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  _buildNumField('総回転数', _rotationController),
                  _buildNumField('差枚', _diffController, allowNegative: true), // ←マイナス対応
                  _buildNumField('BIG回数', _bigController, required: false),
                  _buildNumField('REG回数', _regController, required: false),
                  _buildNumField('重複BIG', _dupBigController, required: false),
                  _buildNumField('重複REG', _dupRegController, required: false),
                  _buildNumField('チェリー', _cherryController, required: false),
                  _buildNumField('ぶどう', _grapeController, required: false),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        widget.recordIndex != null ? '更新' : '保存',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

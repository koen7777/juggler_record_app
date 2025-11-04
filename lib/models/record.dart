class Record {
  final String date;
  final String machine;
  final String shop;
  final String number; // 台番号
  final int totalRotation; // 総回転数
  final int diff;
  final int big;
  final int reg;
  final int bigDup;
  final int regDup;
  final int cherry;
  final int grape;

  Record({
    required this.date,
    required this.machine,
    required this.shop,
    required this.number,
    required this.totalRotation,
    required this.diff,
    required this.big,
    required this.reg,
    required this.bigDup,
    required this.regDup,
    required this.cherry,
    required this.grape,
  });

  // Map形式（DBやJSON用）
  Map<String, dynamic> toMap() => {
        'date': date,
        'machine': machine,
        'shop': shop,
        'number': number,
        'totalRotation': totalRotation,
        'diff': diff,
        'big': big,
        'reg': reg,
        'bigDup': bigDup,
        'regDup': regDup,
        'cherry': cherry,
        'grape': grape,
      };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
        date: map['date'],
        machine: map['machine'],
        shop: map['shop'],
        number: map['number'] ?? '',
        totalRotation: map['totalRotation'] ?? 0,
        diff: map['diff'] ?? 0,
        big: map['big'] ?? 0,
        reg: map['reg'] ?? 0,
        bigDup: map['bigDup'] ?? 0,
        regDup: map['regDup'] ?? 0,
        cherry: map['cherry'] ?? 0,
        grape: map['grape'] ?? 0,
      );

  // CSV用
  List<String> toCsvRow() => [
        date,
        machine,
        shop,
        number,
        totalRotation.toString(),
        diff.toString(),
        big.toString(),
        reg.toString(),
        bigDup.toString(),
        regDup.toString(),
        cherry.toString(),
        grape.toString(),
      ];

  factory Record.fromCsvRow(List<String> cols) => Record(
        date: cols[0],
        machine: cols[1],
        shop: cols[2],
        number: cols[3],
        totalRotation: int.tryParse(cols[4]) ?? 0,
        diff: int.tryParse(cols[5]) ?? 0,
        big: int.tryParse(cols[6]) ?? 0,
        reg: int.tryParse(cols[7]) ?? 0,
        bigDup: int.tryParse(cols[8]) ?? 0,
        regDup: int.tryParse(cols[9]) ?? 0,
        cherry: int.tryParse(cols[10]) ?? 0,
        grape: int.tryParse(cols[11]) ?? 0,
      );

  // ----------------------
  // Web保存用：JSON形式
  // ----------------------
  Map<String, dynamic> toJson() => toMap();

  factory Record.fromJson(Map<String, dynamic> json) => Record.fromMap(json);
}

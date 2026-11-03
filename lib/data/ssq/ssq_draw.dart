///
/// 单个奖级的中奖注数与单注奖金
///
class SsqPrizeGrade {
  ///
  /// 奖级序号 1~6
  ///
  final int type;

  ///
  /// 中奖注数
  ///
  final int count;

  ///
  /// 单注奖金(元),固定奖级为具体金额,浮动奖级为当期单注奖金
  ///
  final int money;

  SsqPrizeGrade({
    required this.type,
    required this.count,
    required this.money,
  });

  factory SsqPrizeGrade.fromJson(Map<String, dynamic> json) {
    return SsqPrizeGrade(
      type: int.tryParse('${json['type']}') ?? 0,
      count: int.tryParse('${json['typenum'] ?? 0}') ?? 0,
      money: int.tryParse('${json['typemoney'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'typenum': count,
      'typemoney': money,
    };
  }
}

///
/// 双色球单期开奖记录
///
class SsqDraw {
  ///
  /// 期号,例如 2026126
  ///
  final String period;

  ///
  /// 开奖日期
  ///
  final DateTime date;

  ///
  /// 红球号码,升序排列
  ///
  final List<int> reds;

  ///
  /// 蓝球号码
  ///
  final int blue;

  ///
  /// 当期销售额(元)
  ///
  final int sales;

  ///
  /// 奖池滚存(元)
  ///
  final int poolMoney;

  ///
  /// 各奖级中奖情况
  ///
  final List<SsqPrizeGrade> grades;

  SsqDraw({
    required this.period,
    required this.date,
    required this.reds,
    required this.blue,
    this.sales = 0,
    this.poolMoney = 0,
    this.grades = const [],
  });

  ///
  /// 解析福彩官网开奖接口返回的单条记录
  ///
  factory SsqDraw.fromOfficial(Map<String, dynamic> json) {
    List<int> reds = _parseBalls(json['red'] ?? '');
    int blue = _parseBalls(json['blue'] ?? '').firstOrNull ?? 0;
    List<SsqPrizeGrade> grades = [];
    final rawGrades = json['prizegrades'];
    if (rawGrades is List) {
      for (final item in rawGrades) {
        if (item is Map) {
          grades.add(SsqPrizeGrade.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SsqDraw(
      period: '${json['code'] ?? ''}',
      date: _parseDate(json['date']),
      reds: reds,
      blue: blue,
      sales: int.tryParse('${json['sales'] ?? 0}') ?? 0,
      poolMoney: int.tryParse('${json['poolmoney'] ?? 0}') ?? 0,
      grades: grades,
    );
  }

  ///
  /// 解析本地缓存中的记录
  ///
  factory SsqDraw.fromJson(Map<String, dynamic> json) {
    List<int> reds = (json['reds'] as List?)
            ?.map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList() ??
        [];
    List<SsqPrizeGrade> grades = [];
    final rawGrades = json['grades'];
    if (rawGrades is List) {
      for (final item in rawGrades) {
        if (item is Map) {
          grades.add(SsqPrizeGrade.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SsqDraw(
      period: '${json['period'] ?? ''}',
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
      reds: reds,
      blue: int.tryParse('${json['blue'] ?? 0}') ?? 0,
      sales: int.tryParse('${json['sales'] ?? 0}') ?? 0,
      poolMoney: int.tryParse('${json['poolMoney'] ?? 0}') ?? 0,
      grades: grades,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'date': date.toIso8601String(),
      'reds': reds,
      'blue': blue,
      'sales': sales,
      'poolMoney': poolMoney,
      'grades': grades.map((e) => e.toJson()).toList(),
    };
  }

  ///
  /// 红球展示串,例如 09 10 13 22 29 32
  ///
  String get redText => reds.map(_twoDigit).join(' ');

  ///
  /// 蓝球展示串
  ///
  String get blueText => _twoDigit(blue);

  ///
  /// 解析逗号或空格分隔的号码串
  ///
  static List<int> _parseBalls(String raw) {
    if (raw.trim().isEmpty) {
      return [];
    }
    List<int> balls = raw
        .split(RegExp(r'[,\s]+'))
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toList();
    balls.sort();
    return balls;
  }

  ///
  /// 解析 2026-11-03(二) 这类日期
  ///
  static DateTime _parseDate(String raw) {
    String head = raw.split('(').first.trim();
    return DateTime.tryParse(head) ?? DateTime.now();
  }

  ///
  /// 两位数补零
  ///
  static String _twoDigit(int value) {
    return value.toString().padLeft(2, '0');
  }
}

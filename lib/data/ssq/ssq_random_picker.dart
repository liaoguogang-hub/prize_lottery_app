import 'dart:math';

///
/// 一注双色球号码
///
class SsqTicket {
  ///
  /// 红球号码,升序
  ///
  final List<int> reds;

  ///
  /// 蓝球号码,升序,复式时为多个
  ///
  final List<int> blues;

  ///
  /// 胆码,胆拖时固定入选;单式与复式为空
  ///
  final List<int> dan;

  SsqTicket({
    required this.reds,
    required this.blues,
    this.dan = const [],
  });

  ///
  /// 是否胆拖玩法
  ///
  bool get isDanTuo => dan.isNotEmpty;

  ///
  /// 拖码个数
  ///
  int get tuoCount => reds.length - dan.length;

  ///
  /// 展开后的总注数
  ///
  int get betCount {
    int t = tuoCount;
    int need = 6 - dan.length;
    if (need < 0 || t < need) {
      return 0;
    }
    int result = 1;
    int k = need > t - need ? t - need : need;
    for (int i = 0; i < k; i++) {
      result = result * (t - i) ~/ (i + 1);
    }
    return result * blues.length;
  }

  ///
  /// 首个蓝球号码,单式时即蓝球
  ///
  int get blue => blues.isEmpty ? 0 : blues.first;

  ///
  /// 红球展示串
  ///
  String get redText => reds.map(_twoDigit).join(' ');

  ///
  /// 蓝球展示串
  ///
  String get blueText => blues.map(_twoDigit).join(' ');

  static String _twoDigit(int value) => value.toString().padLeft(2, '0');
}

///
/// 双色球随机选号器
///
/// 规则: 红球从 01-33 中选 6 个不重复号码, 蓝球从 01-16 中选 1 个
///
class SsqRandomPicker {
  ///
  /// 红球号码上限
  ///
  static const int redMax = 33;

  ///
  /// 蓝球号码上限
  ///
  static const int blueMax = 16;

  ///
  /// 单式红球个数
  ///
  static const int singleRedCount = 6;

  ///
  /// 复式红球个数上限
  ///
  static const int compoundRedMax = 20;

  ///
  /// 胆码个数上限
  ///
  static const int danMax = 5;

  final Random _random;

  SsqRandomPicker({Random? random}) : _random = random ?? Random.secure();

  ///
  /// 机选一注单式号码
  ///
  SsqTicket single() {
    return SsqTicket(
      reds: _pickReds(singleRedCount),
      blues: [_random.nextInt(blueMax) + 1],
    );
  }

  ///
  /// 机选一注复式号码
  ///
  /// [redCount] 红球个数,取值 7-20;[blueCount] 蓝球个数,取值 1-16
  ///
  SsqTicket compound({int redCount = 7, int blueCount = 1}) {
    int reds = redCount.clamp(singleRedCount + 1, compoundRedMax);
    int blues = blueCount.clamp(1, blueMax);
    return SsqTicket(
      reds: _pickReds(reds),
      blues: blues == 1
          ? [_random.nextInt(blueMax) + 1]
          : _pickBlues(blues),
    );
  }

  ///
  /// 机选一注胆拖号码
  ///
  /// [dan] 胆码,固定入选;[tuoCount] 拖码池个数;[blueCount] 蓝球个数
  ///
  SsqTicket danTuo({
    required List<int> dan,
    int tuoCount = 7,
    int blueCount = 1,
  }) {
    List<int> danBalls = _normalize(dan).take(danMax).toList();
    int need = singleRedCount - danBalls.length;
    List<int> pool =
        List.generate(redMax, (i) => i + 1)..removeWhere(danBalls.contains);
    int tuo = tuoCount.clamp(need, pool.length);
    List<int> tuoBalls = _pickFrom(pool, tuo)..sort();
    int blues = blueCount.clamp(1, blueMax);
    return SsqTicket(
      reds: _normalize([...danBalls, ...tuoBalls]),
      blues: blues == 1
          ? [_random.nextInt(blueMax) + 1]
          : _pickBlues(blues),
      dan: danBalls,
    );
  }

  ///
  /// 批量机选单式号码
  ///
  List<SsqTicket> batch(int count) {
    List<SsqTicket> tickets = [];
    for (int i = 0; i < count; i++) {
      tickets.add(single());
    }
    return tickets;
  }

  ///
  /// 无放回抽取 [count] 个红球
  ///
  List<int> _pickReds(int count) {
    return _pickFrom(List.generate(redMax, (i) => i + 1), count)..sort();
  }

  ///
  /// 无放回抽取 [count] 个蓝球
  ///
  List<int> _pickBlues(int count) {
    return _pickFrom(List.generate(blueMax, (i) => i + 1), count)..sort();
  }

  ///
  /// Fisher-Yates 部分洗牌,从 [pool] 中无放回抽取 [count] 个元素
  ///
  List<int> _pickFrom(List<int> pool, int count) {
    int take = count.clamp(0, pool.length);
    for (int i = 0; i < take; i++) {
      int j = i + _random.nextInt(pool.length - i);
      int temp = pool[i];
      pool[i] = pool[j];
      pool[j] = temp;
    }
    return pool.sublist(0, take);
  }

  ///
  /// 号码归一化: 去重、过滤非法值、升序
  ///
  List<int> _normalize(List<int> values) {
    return values.where((e) => e >= 1 && e <= redMax).toSet().toList()..sort();
  }
}

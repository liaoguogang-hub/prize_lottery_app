///
/// 一注彩票的核奖结果
///
class SsqPrizeResult {
  ///
  /// 中奖奖级 1~6,0 表示未中奖
  ///
  final int level;

  ///
  /// 奖级名称
  ///
  final String levelName;

  ///
  /// 本注中奖总金额(元)
  ///
  final int amount;

  ///
  /// 命中红球个数
  ///
  final int hitRed;

  ///
  /// 是否命中蓝球
  ///
  final int hitBlue;

  ///
  /// 展开后的总注数
  ///
  final int bets;

  ///
  /// 中奖注数
  ///
  final int wins;

  ///
  /// 各奖级中奖注数,key 为奖级
  ///
  final Map<int, int> levelCounts;

  SsqPrizeResult({
    required this.level,
    required this.levelName,
    required this.amount,
    required this.hitRed,
    required this.hitBlue,
    required this.bets,
    required this.wins,
    required this.levelCounts,
  });

  ///
  /// 是否中奖
  ///
  bool get hit => level > 0;

  ///
  /// 空结果
  ///
  factory SsqPrizeResult.empty() {
    return SsqPrizeResult(
      level: 0,
      levelName: '未中奖',
      amount: 0,
      hitRed: 0,
      hitBlue: 0,
      bets: 0,
      wins: 0,
      levelCounts: const {},
    );
  }
}

///
/// 双色球核奖器
///
/// 奖级规则:
/// 一等奖 6+1 浮动 | 二等奖 6+0 浮动 | 三等奖 5+1 固定 3000 元
/// 四等奖 5+0 或 4+1 固定 200 元 | 五等奖 4+0 或 3+1 固定 10 元
/// 六等奖 2+1 或 1+1 或 0+1 固定 5 元
///
/// 单式与复式按 6 红 + m 蓝展开,胆拖按「胆码 + 从拖码中选 6-胆数」展开,
/// 各奖级注数用组合数精确计算,不做逐注枚举
///
class SsqPrizeChecker {
  ///
  /// 固定奖级单注奖金
  ///
  static const Map<int, int> fixedAwards = {3: 3000, 4: 200, 5: 10, 6: 5};

  ///
  /// 奖级名称
  ///
  static const Map<int, String> levelNames = {
    1: '一等奖',
    2: '二等奖',
    3: '三等奖',
    4: '四等奖',
    5: '五等奖',
    6: '六等奖',
  };

  ///
  /// 核奖
  ///
  /// [ticketReds] 投注红球(胆拖时为胆码与拖码的合集);
  /// [ticketBlues] 投注蓝球;
  /// [drawReds] 开奖红球;[drawBlue] 开奖蓝球;
  /// [dan] 胆码,胆拖时传入,单式与复式传空;
  /// [firstPrize] 当期一等奖单注奖金;[secondPrize] 当期二等奖单注奖金
  ///
  SsqPrizeResult check({
    required List<int> ticketReds,
    required List<int> ticketBlues,
    required List<int> drawReds,
    required int drawBlue,
    List<int> dan = const [],
    int firstPrize = 0,
    int secondPrize = 0,
  }) {
    List<int> reds =
        ticketReds.where((e) => e >= 1 && e <= 33).toSet().toList()..sort();
    List<int> blues =
        ticketBlues.where((e) => e >= 1 && e <= 16).toSet().toList()..sort();
    if (reds.length < 6 || blues.isEmpty) {
      return SsqPrizeResult.empty();
    }

    ///
    /// 胆码与拖码拆分,胆拖时拖码为红球中去掉胆码的部分
    ///
    List<int> danBalls = dan
        .where((e) => e >= 1 && e <= 33 && reds.contains(e))
        .toSet()
        .toList()
      ..sort();
    if (danBalls.length > 5) {
      danBalls = danBalls.take(5).toList();
    }
    List<int> tuoBalls =
        reds.where((e) => !danBalls.contains(e)).toList()..sort();

    int d = danBalls.length;
    int t = tuoBalls.length;
    int need = 6 - d;
    if (t < need) {
      return SsqPrizeResult.empty();
    }

    int m = blues.length;

    ///
    /// 胆码与拖码分别命中开奖红球的个数
    ///
    int aDan = danBalls.where(drawReds.contains).length;
    int aTuo = tuoBalls.where(drawReds.contains).length;

    ///
    /// 命中 h 个红球的组合数
    ///
    int countOfHits(int h) {
      int j = h - aDan;
      if (j < 0 || j > aTuo) {
        return 0;
      }
      return _binomial(aTuo, j) * _binomial(t - aTuo, need - j);
    }

    ///
    /// 是否命中蓝球,以及未命中的蓝球个数
    ///
    bool blueMatched = blues.contains(drawBlue);
    int missBlue = blueMatched ? m - 1 : m;

    ///
    /// 展开后的总注数
    ///
    int bets = _binomial(t, need) * m;

    Map<int, int> counts = {};

    int c6 = countOfHits(6);
    int c5 = countOfHits(5);
    int c4 = countOfHits(4);
    int c3 = countOfHits(3);
    int c2 = countOfHits(2);
    int c1 = countOfHits(1);
    int c0 = countOfHits(0);

    if (blueMatched) {
      counts[1] = c6;
      counts[3] = c5;
      counts[4] = c4;
      counts[5] = c3;
      counts[6] = c2 + c1 + c0;
    }
    if (missBlue > 0) {
      counts[2] = c6 * missBlue;
      counts[4] = (counts[4] ?? 0) + c5 * missBlue;
      counts[5] = (counts[5] ?? 0) + c4 * missBlue;
    }

    ///
    /// 计算总奖金
    ///
    int amount = 0;
    counts.forEach((level, count) {
      if (count <= 0) {
        return;
      }
      if (level == 1) {
        amount += count * firstPrize;
      } else if (level == 2) {
        amount += count * secondPrize;
      } else {
        amount += count * (fixedAwards[level] ?? 0);
      }
    });

    int wins = counts.values.fold(0, (sum, e) => sum + e);
    int best = 0;
    counts.forEach((level, count) {
      if (count > 0 && (best == 0 || level < best)) {
        best = level;
      }
    });

    return SsqPrizeResult(
      level: best,
      levelName: best == 0 ? '未中奖' : levelNames[best]!,
      amount: amount,
      hitRed: aDan + aTuo,
      hitBlue: blueMatched ? 1 : 0,
      bets: bets,
      wins: wins,
      levelCounts: counts,
    );
  }

  ///
  /// 组合数 C(n, k)
  ///
  int _binomial(int n, int k) {
    if (k < 0 || k > n || n < 0) {
      return 0;
    }
    if (k == 0 || k == n) {
      return 1;
    }
    int kk = k > n - k ? n - k : k;
    double result = 1;
    for (int i = 0; i < kk; i++) {
      result = result * (n - i) / (i + 1);
    }
    return result.round();
  }
}

import 'dart:math';

import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';
import 'package:prize_lottery_app/data/ssq/ssq_random_picker.dart';

///
/// 预测策略
///
enum SsqPredictStrategy {
  ///
  /// 热号追随: 取窗口内出现频率最高的号码
  ///
  hot('热号追随'),

  ///
  /// 冷号逆向: 取窗口内出现频率最低的号码
  ///
  cold('冷号逆向'),

  ///
  /// 遗漏回归: 取当前遗漏期数最大的号码
  ///
  omission('遗漏回归'),

  ///
  /// 均衡分布: 在奇偶比、大小比、和值区间上做均衡约束
  ///
  balanced('均衡分布'),

  ///
  /// 均值回归: 取频率向长期均值回归的号码
  ///
  meanReversion('均值回归'),

  ///
  /// 综合集成: 按各策略近期回测表现加权投票
  ///
  ensemble('综合集成');

  final String label;

  const SsqPredictStrategy(this.label);
}

///
/// 窗口内的号码统计
///
class SsqStats {
  ///
  /// 红球出现次数
  ///
  final Map<int, int> redFrequency;

  ///
  /// 蓝球出现次数
  ///
  final Map<int, int> blueFrequency;

  ///
  /// 红球当前遗漏期数
  ///
  final Map<int, int> redOmission;

  ///
  /// 蓝球当前遗漏期数
  ///
  final Map<int, int> blueOmission;

  ///
  /// 统计窗口期数
  ///
  final int window;

  SsqStats({
    required this.redFrequency,
    required this.blueFrequency,
    required this.redOmission,
    required this.blueOmission,
    required this.window,
  });

  ///
  /// 窗口内每个红球的期望出现次数
  ///
  double get expectedRed => window / 33.0;

  ///
  /// 窗口内每个蓝球的期望出现次数
  ///
  double get expectedBlue => window / 16.0;
}

///
/// 单个策略的回测表现
///
class SsqStrategyReport {
  ///
  /// 策略
  ///
  final SsqPredictStrategy strategy;

  ///
  /// 回测期数
  ///
  final int rounds;

  ///
  /// 命中任意奖级的次数
  ///
  final int hits;

  ///
  /// 累计命中红球个数
  ///
  final int redHits;

  ///
  /// 中奖率
  ///
  double get hitRate => rounds == 0 ? 0 : hits / rounds;

  ///
  /// 平均命中红球个数
  ///
  double get averageRedHits => rounds == 0 ? 0 : redHits / rounds;

  SsqStrategyReport({
    required this.strategy,
    required this.rounds,
    required this.hits,
    required this.redHits,
  });
}

///
/// 回测报告
///
class SsqBacktestReport {
  ///
  /// 各策略表现
  ///
  final List<SsqStrategyReport> reports;

  ///
  /// 随机基准表现
  ///
  final SsqStrategyReport baseline;

  SsqBacktestReport({required this.reports, required this.baseline});

  ///
  /// 是否有策略优于随机基准
  ///
  bool get beatsBaseline {
    return reports.any((e) => e.hitRate > baseline.hitRate);
  }
}

///
/// 双色球预测器
///
/// 所有策略均在本地基于历史开奖数据计算,不依赖任何服务端接口
///
class SsqPredictor {
  ///
  /// 默认统计窗口
  ///
  static const int defaultWindow = 100;

  ///
  /// 计算窗口统计
  ///
  /// [draws] 按期号倒序排列的开奖记录,draws[0] 为最新一期
  ///
  SsqStats analyze(List<SsqDraw> draws, {int window = defaultWindow}) {
    int size = min(window, draws.length);
    Map<int, int> redFrequency = {};
    Map<int, int> blueFrequency = {};
    for (int i = 1; i <= 33; i++) {
      redFrequency[i] = 0;
    }
    for (int i = 1; i <= 16; i++) {
      blueFrequency[i] = 0;
    }
    for (int i = 0; i < size; i++) {
      for (int red in draws[i].reds) {
        redFrequency[red] = (redFrequency[red] ?? 0) + 1;
      }
      blueFrequency[draws[i].blue] = (blueFrequency[draws[i].blue] ?? 0) + 1;
    }
    return SsqStats(
      redFrequency: redFrequency,
      blueFrequency: blueFrequency,
      redOmission: _omission(draws, size, 33, (d) => d.reds),
      blueOmission: _omission(draws, size, 16, (d) => [d.blue]),
      window: size,
    );
  }

  ///
  /// 计算每个号码的当前遗漏期数
  ///
  Map<int, int> _omission(
    List<SsqDraw> draws,
    int size,
    int max,
    List<int> Function(SsqDraw) pick,
  ) {
    Map<int, int> omission = {};
    for (int i = 1; i <= max; i++) {
      omission[i] = size;
    }
    for (int i = 0; i < size; i++) {
      for (int number in pick(draws[i])) {
        if (omission[number] == size) {
          omission[number] = i;
        }
      }
    }
    return omission;
  }

  ///
  /// 按策略生成一组推荐号码
  ///
  /// 每注号码按策略权重做加权抽样产生,因此多注结果互不相同,
  /// 同时每注都保持对该策略的偏好
  ///
  List<SsqTicket> predict(
    List<SsqDraw> history, {
    SsqPredictStrategy strategy = SsqPredictStrategy.ensemble,
    int window = defaultWindow,
    int count = 5,
    Random? random,
  }) {
    if (history.isEmpty) {
      return [];
    }
    SsqStats stats = analyze(history, window: window);
    Random rnd = random ?? Random.secure();
    List<SsqTicket> tickets = [];
    for (int i = 0; i < count; i++) {
      Map<int, double> redWeights = _redWeights(stats, strategy, rnd);
      Map<int, double> blueWeights = _blueWeights(stats, strategy);
      List<int> reds = _sampleRed(redWeights, strategy, rnd);
      if (reds.length != 6) {
        continue;
      }
      tickets.add(SsqTicket(reds: reds, blues: _sampleBlue(blueWeights, rnd)));
    }
    return tickets;
  }

  ///
  /// 各策略的红球权重
  ///
  Map<int, double> _redWeights(
    SsqStats stats,
    SsqPredictStrategy strategy,
    Random rnd,
  ) {
    Map<int, double> weights = {};
    switch (strategy) {
      case SsqPredictStrategy.hot:
        stats.redFrequency.forEach((k, v) => weights[k] = v.toDouble());
        break;
      case SsqPredictStrategy.cold:
        stats.redFrequency.forEach((k, v) =>
            weights[k] = (stats.expectedRed * 2 - v).clamp(0.5, 1000).toDouble());
        break;
      case SsqPredictStrategy.omission:
        stats.redOmission.forEach((k, v) => weights[k] = v.toDouble());
        break;
      case SsqPredictStrategy.meanReversion:
        stats.redFrequency.forEach((k, v) =>
            weights[k] = (stats.expectedRed - v).clamp(0.5, 1000).toDouble());
        break;
      case SsqPredictStrategy.balanced:
        stats.redFrequency.forEach((k, v) =>
            weights[k] = 1.0 / (1 + (v - stats.expectedRed).abs()));
        break;
      case SsqPredictStrategy.ensemble:
        _ensembleVotes(stats).forEach((k, v) => weights[k] = v);
        break;
    }
    return weights;
  }

  ///
  /// 各策略的蓝球权重
  ///
  Map<int, double> _blueWeights(SsqStats stats, SsqPredictStrategy strategy) {
    Map<int, double> weights = {};
    switch (strategy) {
      case SsqPredictStrategy.hot:
        stats.blueFrequency.forEach((k, v) => weights[k] = v.toDouble());
        break;
      case SsqPredictStrategy.cold:
        stats.blueFrequency.forEach((k, v) =>
            weights[k] = (stats.expectedBlue * 2 - v).clamp(0.5, 1000).toDouble());
        break;
      case SsqPredictStrategy.omission:
        stats.blueOmission.forEach((k, v) => weights[k] = v.toDouble());
        break;
      case SsqPredictStrategy.meanReversion:
        stats.blueFrequency.forEach((k, v) =>
            weights[k] = (stats.expectedBlue - v).clamp(0.5, 1000).toDouble());
        break;
      case SsqPredictStrategy.balanced:
        stats.blueFrequency.forEach((k, v) =>
            weights[k] = 1.0 / (1 + (v - stats.expectedBlue).abs()));
        break;
      case SsqPredictStrategy.ensemble:
        stats.blueFrequency.forEach((k, v) => weights[k] = 1.0 + v.toDouble());
        break;
    }
    return weights;
  }

  ///
  /// 综合集成的各号码投票
  ///
  Map<int, double> _ensembleVotes(SsqStats stats) {
    Map<int, double> votes = {};
    for (int i = 1; i <= 33; i++) {
      votes[i] = 0;
    }

    void add(Map<int, int> weightMap, int top, double factor) {
      List<int> keys = weightMap.keys.toList()
        ..sort((a, b) {
          int cmp = (weightMap[b] ?? 0).compareTo(weightMap[a] ?? 0);
          return cmp != 0 ? cmp : a.compareTo(b);
        });
      for (int number in keys.take(top)) {
        votes[number] = votes[number]! + factor;
      }
    }

    /// 热号
    add(stats.redFrequency, 10, 1.4);
    /// 遗漏
    add(stats.redOmission, 10, 1.1);
    /// 冷号(频率取负后取前 10)
    Map<int, int> inverted = {};
    stats.redFrequency.forEach((k, v) => inverted[k] = -v);
    add(inverted, 10, 0.8);
    /// 均值回归(偏离期望越远越靠前)
    Map<int, int> deviation = {};
    stats.redFrequency.forEach((k, v) =>
        deviation[k] = -((v - stats.expectedRed).abs() * 10).round());
    add(deviation, 12, 1.0);
    /// 均衡分布(频率越接近期望越靠前)
    Map<int, int> closeness = {};
    stats.redFrequency.forEach((k, v) =>
        closeness[k] = -((v - stats.expectedRed).abs() * 10).round());
    add(closeness, 12, 1.2);

    return votes;
  }

  ///
  /// 按权重无放回抽样
  ///
  List<int> _weightedPick(Map<int, double> weights, int count, Random rnd) {
    List<int> pool = weights.keys.toList();
    List<int> picked = [];
    while (picked.length < count && pool.isNotEmpty) {
      double total = pool.fold(
          0.0, (sum, e) => sum + (weights[e] ?? 0.5).clamp(0.5, 100000));
      if (total <= 0) {
        picked.add(pool.removeAt(rnd.nextInt(pool.length)));
        continue;
      }
      double target = rnd.nextDouble() * total;
      double acc = 0;
      for (int i = 0; i < pool.length; i++) {
        acc += (weights[pool[i]] ?? 0.5).clamp(0.5, 100000);
        if (target < acc) {
          picked.add(pool.removeAt(i));
          break;
        }
      }
      if (picked.length < count && pool.isNotEmpty && picked.isEmpty) {
        picked.add(pool.removeAt(rnd.nextInt(pool.length)));
      }
    }
    return picked;
  }

  ///
  /// 抽样红球,均衡类策略再做一次约束修复
  ///
  List<int> _sampleRed(
    Map<int, double> weights,
    SsqPredictStrategy strategy,
    Random rnd,
  ) {
    List<int> picked = _weightedPick(weights, 6, rnd)..sort();
    bool needBalance = strategy == SsqPredictStrategy.balanced ||
        strategy == SsqPredictStrategy.ensemble;
    if (!needBalance || _balancedValid(picked)) {
      return picked;
    }

    ///
    /// 逐个换号尝试修复约束,取权重损失最小的合法组合
    ///
    List<int> pool = weights.keys.toList().where((e) => !picked.contains(e)).toList();
    List<int>? best;
    double bestScore = double.negativeInfinity;
    for (int out in picked) {
      for (int candidate in pool) {
        List<int> attempt = [...picked.where((e) => e != out), candidate]..sort();
        if (!_balancedValid(attempt)) {
          continue;
        }
        double score = attempt.fold(
            0.0, (sum, e) => sum + (weights[e] ?? 0.5));
        if (score > bestScore) {
          bestScore = score;
          best = attempt;
        }
      }
    }
    return best ?? picked;
  }

  ///
  /// 抽样蓝球
  ///
  List<int> _sampleBlue(Map<int, double> weights, Random rnd) {
    return _weightedPick(weights, 1, rnd);
  }

  ///
  /// 均衡约束是否满足
  ///
  /// 奇偶比、大小比在 2:4~4:2 之间,和值在 80~130,三分区至少各命中一个
  ///
  bool _balancedValid(List<int> picked) {
    if (picked.length != 6) {
      return false;
    }
    int odd = picked.where((e) => e.isOdd).length;
    if (odd < 2 || odd > 4) {
      return false;
    }
    int big = picked.where((e) => e > 16).length;
    if (big < 2 || big > 4) {
      return false;
    }
    int sum = picked.fold(0, (a, b) => a + b);
    if (sum < 80 || sum > 130) {
      return false;
    }
    if (picked.where((e) => e <= 11).isEmpty) {
      return false;
    }
    if (picked.where((e) => e >= 23).isEmpty) {
      return false;
    }
    return true;
  }

  ///
  /// 滚动回测: 用每一期之前的数据生成推荐,与真实开奖比对
  ///
  /// [rounds] 回测轮数;[window] 每轮使用的历史窗口
  ///
  SsqBacktestReport backtest(
    List<SsqDraw> history, {
    int rounds = 100,
    int window = defaultWindow,
    int seed = 20260101,
  }) {
    Map<SsqPredictStrategy, List<int>> hits = {};
    Map<SsqPredictStrategy, List<int>> redHits = {};
    for (SsqPredictStrategy strategy in SsqPredictStrategy.values) {
      hits[strategy] = [];
      redHits[strategy] = [];
    }
    List<int> baselineHits = [];
    List<int> baselineRedHits = [];

    int usable = min(rounds, history.length - 2);
    for (int i = 0; i < usable; i++) {
      ///
      /// history[0] 为最新一期,回测第 i 轮时可用数据为 history[i+1..]
      ///
      List<SsqDraw> past = history.sublist(i + 1);
      SsqDraw actual = history[i];

      for (SsqPredictStrategy strategy in SsqPredictStrategy.values) {
        List<SsqTicket> tickets = predict(
          past,
          strategy: strategy,
          window: window,
          count: 1,
          random: Random(seed + i * 31 + strategy.index),
        );
        if (tickets.isEmpty) {
          continue;
        }
        int hitRed = tickets.first.reds.where(actual.reds.contains).length;
        bool hitBlue = tickets.first.blue == actual.blue;
        redHits[strategy]!.add(hitRed);
        hits[strategy]!.add((hitRed >= 4 && hitBlue) ||
            hitRed >= 5 ||
            hitRed == 6
                ? 1
                : 0);
      }

      ///
      /// 随机基准
      ///
      SsqRandomPicker picker = SsqRandomPicker(random: Random(seed + i * 977));
      SsqTicket baseline = picker.single();
      int baselineRed = baseline.reds.where(actual.reds.contains).length;
      bool baselineBlue = baseline.blue == actual.blue;
      baselineRedHits.add(baselineRed);
      baselineHits.add(
          (baselineRed >= 4 && baselineBlue) ||
                  baselineRed >= 5 ||
                  baselineRed == 6
              ? 1
              : 0);
    }

    List<SsqStrategyReport> reports = SsqPredictStrategy.values
        .map((strategy) => SsqStrategyReport(
              strategy: strategy,
              rounds: hits[strategy]!.length,
              hits: hits[strategy]!.fold(0, (a, b) => a + b),
              redHits: redHits[strategy]!.fold(0, (a, b) => a + b),
            ))
        .toList();

    return SsqBacktestReport(
      reports: reports,
      baseline: SsqStrategyReport(
        strategy: SsqPredictStrategy.hot,
        rounds: baselineHits.length,
        hits: baselineHits.fold(0, (a, b) => a + b),
        redHits: baselineRedHits.fold(0, (a, b) => a + b),
      ),
    );
  }
}

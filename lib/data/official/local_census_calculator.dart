import 'package:prize_lottery_app/views/census/model/dlt_chart_census.dart';
import 'package:prize_lottery_app/views/census/model/qlc_chart_census.dart';
import 'package:prize_lottery_app/views/census/model/ssq_chart_census.dart';
import 'package:prize_lottery_app/views/lottery/model/lottery_info.dart';

///
/// 本地统计计算
///
/// 上游的「综合分析 / 整体分析」等页面依赖服务端预计算的选号统计,服务端下线后
/// 改为按官方开奖记录在本地计算,输出结构与原接口一致,页面无需改动。
///
/// 统计口径(与上游图例对应):
/// - 三胆 / 12码 / 20码 / 25码:号码在最近 N 期的出现次数,条形越长越热
/// - 杀三码 / 杀六码:号码在最近 N 期未出现的期数,条形越长越冷
/// - 蓝球三胆 / 蓝球五码:蓝球在最近 N 期的出现次数
/// - 蓝球杀码:蓝球在最近 N 期未出现的期数
///
class LocalCensusCalculator {
  ///
  /// 计算双色球选号统计
  ///
  static SsqChartCensus buildSsq(List<LotteryInfo> draws) {
    return SsqChartCensus.fromJson(buildSsqJson(draws));
  }

  ///
  /// 双色球选号统计原始结构
  ///
  static Map<String, dynamic> buildSsqJson(List<LotteryInfo> draws) {
    return buildNumberTypeJson(
      draws: draws,
      redWindows: const [1, 2, 3, 12, 20, 25],
      redKillWindows: const [3, 6],
      redKillPrefix: 'rk',
      blueWindows: const [3, 5],
      blueKillWindows: const [6],
      redMax: 33,
      blueMax: 16,
    );
  }

  ///
  /// 计算大乐透选号统计
  ///
  static DltChartCensus buildDlt(List<LotteryInfo> draws) {
    return DltChartCensus.fromJson(buildDltJson(draws));
  }

  ///
  /// 大乐透选号统计原始结构
  ///
  static Map<String, dynamic> buildDltJson(List<LotteryInfo> draws) {
    return buildNumberTypeJson(
      draws: draws,
      redWindows: const [2, 3, 10, 20],
      redKillWindows: const [3, 6],
      redKillPrefix: 'rk',
      blueWindows: const [2, 6],
      blueKillWindows: const [6],
      redMax: 35,
      blueMax: 12,
    );
  }

  ///
  /// 计算七乐彩选号统计
  ///
  static QlcChartCensus buildQlc(List<LotteryInfo> draws) {
    return QlcChartCensus.fromJson(buildQlcJson(draws));
  }

  ///
  /// 七乐彩选号统计原始结构
  ///
  static Map<String, dynamic> buildQlcJson(List<LotteryInfo> draws) {
    return buildNumberTypeJson(
      draws: draws,
      redWindows: const [1, 2, 3, 12, 18, 22],
      redKillWindows: const [3, 6],
      redKillPrefix: 'k',
      blueWindows: const [],
      blueKillWindows: const [],
      redMax: 30,
      blueMax: 30,
    );
  }

  ///
  /// 通用数字型彩种统计
  ///
  /// [redWindows] 红球统计窗口;[redKillWindows] 红球杀号窗口;
  /// [blueWindows] 蓝球统计窗口;[blueKillWindows] 蓝球杀号窗口(空表示该彩种无蓝球统计)
  ///
  static Map<String, dynamic> buildNumberTypeJson({
    required List<LotteryInfo> draws,
    required List<int> redWindows,
    required List<int> redKillWindows,
    required String redKillPrefix,
    required List<int> blueWindows,
    required List<int> blueKillWindows,
    required int redMax,
    required int blueMax,
  }) {
    List<List<int>> reds = [];
    List<List<int>> blues = [];
    for (LotteryInfo draw in draws) {
      reds.add(_parse(draw.redBalls()));
      blues.add(_parse(draw.blueBalls()));
    }

    Map<String, dynamic> json = {
      'period': draws.isEmpty ? '' : draws.first.period,
    };

    for (int window in redWindows) {
      json['r$window'] = _wrap(_count(reds, window, redMax));
    }
    for (int window in redKillWindows) {
      json['$redKillPrefix$window'] = _wrap(_miss(reds, window, redMax));
    }
    for (int window in blueWindows) {
      json['b$window'] = _wrap(_count(blues, window, blueMax));
    }
    if (blueKillWindows.isNotEmpty) {
      json['bk'] = _wrap(_miss(blues, blueKillWindows.first, blueMax));
    }

    return json;
  }

  ///
  /// 号码在最近 [window] 期的出现次数
  ///
  static List<int> _count(List<List<int>> draws, int window, int max) {
    List<int> counts = List.filled(max, 0);
    int limit = window > draws.length ? draws.length : window;
    for (int i = 0; i < limit; i++) {
      for (int n in draws[i]) {
        if (n >= 1 && n <= max) {
          counts[n - 1]++;
        }
      }
    }
    return counts;
  }

  ///
  /// 号码在最近 [window] 期未出现的期数
  ///
  static List<int> _miss(List<List<int>> draws, int window, int max) {
    List<int> counts = _count(draws, window, max);
    int limit = window > draws.length ? draws.length : window;
    for (int i = 0; i < max; i++) {
      counts[i] = limit - counts[i];
    }
    return counts;
  }

  ///
  /// 包装成上游统计结构
  ///
  /// 上游用 int.parse 解析这些数值,故此处必须输出字符串
  ///
  static Map<String, dynamic> _wrap(List<int> values) {
    return {
      'values': [
        values.map((e) => '$e').toList(),
      ],
    };
  }

  ///
  /// 解析号码串
  ///
  static List<int> _parse(List<String> balls) {
    List<int> result = [];
    for (String ball in balls) {
      int? value = int.tryParse(ball);
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }
}

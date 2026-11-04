import 'package:prize_lottery_app/views/lottery/model/lottery_info.dart';
import 'package:prize_lottery_app/views/lottery/model/lottery_omit.dart';

///
/// 号码遗漏本地计算
///
/// 上游的遗漏数据由服务端按彩种预计算后下发,服务端下线后改为在本地依据
/// 官方开奖记录推算,结果结构与原接口一致,走势图等页面无需改动即可复用。
///
class LocalOmitCalculator {
  ///
  /// 数字型彩种的号码池 [红球上限, 蓝球上限]
  ///
  static const Map<String, List<int>> ballPools = {
    'ssq': [33, 16],
    'dlt': [35, 12],
    'qlc': [30, 30],
    'kl8': [80, 0],
  };

  ///
  /// 位数型彩种(各位数字 0-9)
  ///
  static const Map<String, int> digitTypes = {
    'fc3d': 3,
    'pl3': 3,
    'pl5': 5,
  };

  ///
  /// 计算号码遗漏
  ///
  /// [ascending] 需按期号升序排列,遗漏值表示该号码截至当期已连续多少期未出现,
  /// 当期中出则为 0。
  ///
  static List<LotteryOmit> build(String type, List<LotteryInfo> ascending) {
    if (ballPools.containsKey(type)) {
      return _buildBallOmits(type, ascending);
    }
    if (digitTypes.containsKey(type)) {
      return _buildDigitOmits(type, ascending);
    }
    return [];
  }

  ///
  /// 数字型彩种:红球 + 蓝球
  ///
  static List<LotteryOmit> _buildBallOmits(
      String type, List<LotteryInfo> ascending) {
    int redMax = ballPools[type]![0];
    int blueMax = ballPools[type]![1];
    Map<int, int> redSeen = {};
    Map<int, int> blueSeen = {};
    List<LotteryOmit> result = [];

    for (int i = 0; i < ascending.length; i++) {
      LotteryInfo draw = ascending[i];
      Set<int> reds = _parse(draw.redBalls());
      Set<int> blues = _parse(draw.blueBalls());

      List<Map<String, dynamic>> redValues = [];
      for (int n = 1; n <= redMax; n++) {
        redValues.add({
          'key': n.toString().padLeft(2, '0'),
          'value': _omit(reds, redSeen, n, i),
        });
      }

      List<Map<String, dynamic>> blueValues = [];
      for (int n = 1; n <= blueMax; n++) {
        blueValues.add({
          'key': n.toString().padLeft(2, '0'),
          'value': _omit(blues, blueSeen, n, i),
        });
      }

      result.add(_wrap(type, draw.period, redValues, blueValues, null));
    }
    return result;
  }

  ///
  /// 位数型彩种:每位一个 0-9 的遗漏序列(cb1..cbN)
  ///
  static List<LotteryOmit> _buildDigitOmits(
      String type, List<LotteryInfo> ascending) {
    int digits = digitTypes[type]!;
    List<Map<int, int>> seen = List.generate(digits, (_) => {});
    List<LotteryOmit> result = [];

    for (int i = 0; i < ascending.length; i++) {
      LotteryInfo draw = ascending[i];
      List<int> balls = draw.redBalls().map((e) => int.tryParse(e) ?? -1).toList();
      List<List<Map<String, dynamic>>> positions = [];

      for (int p = 0; p < digits; p++) {
        int current = p < balls.length ? balls[p] : -1;
        List<Map<String, dynamic>> values = [];
        for (int n = 0; n <= 9; n++) {
          bool hit = current == n;
          int value;
          if (hit) {
            value = 0;
            seen[p][n] = i;
          } else {
            value = seen[p].containsKey(n) ? i - seen[p][n]! : i + 1;
          }
          values.add({'key': '$n', 'value': value});
        }
        positions.add(values);
      }

      result.add(_wrapDigit(type, draw.period, positions));
    }
    return result;
  }

  ///
  /// 单个号码的遗漏值
  ///
  static int _omit(Set<int> hits, Map<int, int> seen, int number, int index) {
    if (hits.contains(number)) {
      seen[number] = index;
      return 0;
    }
    if (seen.containsKey(number)) {
      return index - seen[number]!;
    }
    return index + 1;
  }

  ///
  /// 解析号码串
  ///
  static Set<int> _parse(List<String> balls) {
    Set<int> result = {};
    for (String ball in balls) {
      int? value = int.tryParse(ball);
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }

  ///
  /// 组装数字型记录
  ///
  static LotteryOmit _wrap(
    String type,
    String period,
    List<Map<String, dynamic>>? red,
    List<Map<String, dynamic>>? blue,
    Map<String, dynamic>? extra,
  ) {
    Map<String, dynamic> json = {
      'period': period,
      'type': {'value': 1, 'description': type},
      'gmtCreate': '',
    };
    if (red != null) {
      json['red'] = {'values': red};
    }
    if (blue != null) {
      json['blue'] = {'values': blue};
    }
    if (extra != null) {
      json['extra'] = extra;
    }
    return LotteryOmit.fromJson(json);
  }

  ///
  /// 组装位数型记录
  ///
  static LotteryOmit _wrapDigit(
    String type,
    String period,
    List<List<Map<String, dynamic>>> positions,
  ) {
    Map<String, dynamic> json = {
      'period': period,
      'type': {'value': 1, 'description': type},
      'gmtCreate': '',
    };
    const List<String> names = ['cb1', 'cb2', 'cb3', 'cb4', 'cb5'];
    for (int i = 0; i < positions.length && i < names.length; i++) {
      json[names[i]] = {'values': positions[i]};
    }
    return LotteryOmit.fromJson(json);
  }
}

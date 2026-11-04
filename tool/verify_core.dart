import 'dart:math';

import 'package:prize_lottery_app/data/official/local_census_calculator.dart';
import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';
import 'package:prize_lottery_app/views/lottery/model/lottery_info.dart';
import 'package:prize_lottery_app/data/ssq/ssq_prize_checker.dart';
import 'package:prize_lottery_app/data/ssq/ssq_predictor.dart';
import 'package:prize_lottery_app/data/ssq/ssq_random_picker.dart';

int failures = 0;

void check(String name, bool ok, [String detail = '']) {
  if (ok) {
    print('  PASS  $name');
  } else {
    failures++;
    print('  FAIL  $name  $detail');
  }
}

void main() {
  final checker = SsqPrizeChecker();
  final drawRed = [9, 10, 13, 22, 29, 32];
  const drawBlue = 12;

  print('== 奖级判定(单式)==');
  // 6+1 一等奖
  var r = checker.check(
      ticketReds: drawRed, ticketBlues: [12], drawReds: drawRed, drawBlue: 12);
  check('6+1 -> 一等奖', r.level == 1 && r.wins == 1, 'got ${r.levelName}');
  // 6+0 二等奖
  r = checker.check(
      ticketReds: drawRed, ticketBlues: [11], drawReds: drawRed, drawBlue: 12);
  check('6+0 -> 二等奖', r.level == 2 && r.wins == 1, 'got ${r.levelName}');
  // 5+1 三等奖
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 29, 1],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('5+1 -> 三等奖 3000', r.level == 3 && r.amount == 3000, 'got ${r.levelName} ${r.amount}');
  // 5+0 四等奖
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 29, 1],
      ticketBlues: [11],
      drawReds: drawRed,
      drawBlue: 12);
  check('5+0 -> 四等奖 200', r.level == 4 && r.amount == 200, 'got ${r.levelName} ${r.amount}');
  // 4+1 四等奖
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 1, 2],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('4+1 -> 四等奖 200', r.level == 4 && r.amount == 200, 'got ${r.levelName} ${r.amount}');
  // 4+0 五等奖
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 1, 2],
      ticketBlues: [11],
      drawReds: drawRed,
      drawBlue: 12);
  check('4+0 -> 五等奖 10', r.level == 5 && r.amount == 10, 'got ${r.levelName} ${r.amount}');
  // 3+1 五等奖
  r = checker.check(
      ticketReds: [9, 10, 13, 1, 2, 3],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('3+1 -> 五等奖 10', r.level == 5 && r.amount == 10, 'got ${r.levelName} ${r.amount}');
  // 2+1 六等奖
  r = checker.check(
      ticketReds: [9, 10, 1, 2, 3, 4],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('2+1 -> 六等奖 5', r.level == 6 && r.amount == 5, 'got ${r.levelName} ${r.amount}');
  // 0+1 六等奖
  r = checker.check(
      ticketReds: [1, 2, 3, 4, 5, 6],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('0+1 -> 六等奖 5', r.level == 6 && r.amount == 5, 'got ${r.levelName} ${r.amount}');
  // 0+0 未中奖
  r = checker.check(
      ticketReds: [1, 2, 3, 4, 5, 6],
      ticketBlues: [11],
      drawReds: drawRed,
      drawBlue: 12);
  check('0+0 -> 未中奖', r.level == 0 && r.amount == 0, 'got ${r.levelName}');

  print('== 复式组合数核对 ==');
  // 7 红 1 蓝 = C(7,6)=7 注
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 29, 32, 1],
      ticketBlues: [12],
      drawReds: drawRed,
      drawBlue: 12);
  check('复式7红总注数=7', r.bets == 7, 'got ${r.bets}');
  // 其中 1 组 6 红全中 -> 一等奖 1 注
  check('复式7红中一等奖1注', r.levelCounts[1] == 1, 'got ${r.levelCounts[1]}');
  // 另 6 组各命中 5 红 + 蓝 -> 三等奖 6 注
  check('复式7红中三等奖6注', r.levelCounts[3] == 6, 'got ${r.levelCounts[3]}');
  check('复式7红总奖=一等奖+三等奖',
      r.amount == 1 * 0 + 6 * 3000, 'got ${r.amount}');

  // 8 红 2 蓝 = C(8,6)*2 = 56 注
  r = checker.check(
      ticketReds: [9, 10, 13, 22, 29, 32, 1, 2],
      ticketBlues: [12, 11],
      drawReds: drawRed,
      drawBlue: 12);
  check('复式8红2蓝总注数=56', r.bets == 56, 'got ${r.bets}');

  print('== 机选约束 ==');
  final picker = SsqRandomPicker(random: Random(42));
  bool ok = true;
  for (int i = 0; i < 3000; i++) {
    final t = picker.single();
    if (t.reds.length != 6 ||
        t.reds.toSet().length != 6 ||
        t.reds.any((e) => e < 1 || e > 33) ||
        t.blues.length != 1 ||
        t.blues.first < 1 ||
        t.blues.first > 16) {
      ok = false;
      break;
    }
  }
  check('3000 次机选均满足规则', ok);

  final compound = picker.compound(redCount: 12, blueCount: 3);
  check('复式机选红球12个不重复',
      compound.reds.length == 12 && compound.reds.toSet().length == 12);
  check('复式机选蓝球3个不重复',
      compound.blues.length == 3 && compound.blues.toSet().length == 3);

  final danTuoCheck = picker.danTuo(dan: [9, 10], tuoCount: 8);
  check('胆拖包含全部胆码',
      danTuoCheck.reds.contains(9) && danTuoCheck.reds.contains(10));
  check('胆拖红球数=10', danTuoCheck.reds.length == 10);
  check('胆拖注数=70', danTuoCheck.betCount == 70, 'got ${danTuoCheck.betCount}');

  print('== 胆拖组合数核对 ==');
  // 构造确定性的胆拖: 胆码 9,10 + 拖码含 13,22,29,32 => 必中 6 红
  final fixedDanTuo = SsqTicket(
    reds: [9, 10, 13, 22, 29, 32, 1, 2, 3, 4],
    blues: [12],
    dan: [9, 10],
  );
  r = checker.check(
      ticketReds: fixedDanTuo.reds,
      ticketBlues: fixedDanTuo.blues,
      dan: fixedDanTuo.dan,
      drawReds: drawRed,
      drawBlue: 12);
  check('核奖注数=70', r.bets == 70, 'got ${r.bets}');
  check('胆拖可命中一等奖', r.level == 1, 'got ${r.levelName}');
  check('胆拖一等奖注数=1', r.levelCounts[1] == 1, 'got ${r.levelCounts[1]}');
  // 去掉一个中奖红球后最多命中 5 红 + 蓝 => 三等奖
  final missOneDanTuo = SsqTicket(
    reds: [9, 10, 13, 22, 29, 5, 1, 2, 3, 4],
    blues: [12],
    dan: [9, 10],
  );
  r = checker.check(
      ticketReds: missOneDanTuo.reds,
      ticketBlues: missOneDanTuo.blues,
      dan: missOneDanTuo.dan,
      drawReds: drawRed,
      drawBlue: 12);
  check('胆拖差一红降为三等奖', r.level == 3, 'got ${r.levelName}');
  check('胆拖命中红球数为5', r.hitRed == 5, 'got ${r.hitRed}');

  print('== 预测器 ==');
  final draws = <SsqDraw>[];
  final rnd = Random(7);
  for (int i = 0; i < 400; i++) {
    final pool = List.generate(33, (k) => k + 1);
    final reds = <int>[];
    for (int k = 0; k < 6; k++) {
      reds.add(pool.removeAt(rnd.nextInt(pool.length)));
    }
    draws.add(SsqDraw(
      period: '2026${(400 - i).toString().padLeft(3, '0')}',
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      reds: reds..sort(),
      blue: rnd.nextInt(16) + 1,
    ));
  }
  final predictor = SsqPredictor();
  final stats = predictor.analyze(draws, window: 100);
  check('统计窗口=100', stats.window == 100);
  check('红球频率表覆盖 33 个号', stats.redFrequency.length == 33);
  check('红球出现总次数=600', stats.redFrequency.values.fold(0, (a, b) => a + b) == 600);

  for (final strategy in SsqPredictStrategy.values) {
    final tickets = predictor.predict(draws, strategy: strategy, count: 5);
    final valid = tickets.length == 5 &&
        tickets.every((t) =>
            t.reds.length == 6 &&
            t.reds.toSet().length == 6 &&
            t.reds.every((e) => e >= 1 && e <= 33) &&
            t.blue >= 1 &&
            t.blue <= 16);
    check('策略 ${strategy.label} 产出合法号码', valid);
  }

  final report = predictor.backtest(draws, rounds: 60, window: 50);
  check('回测轮数=60', report.baseline.rounds == 60, 'got ${report.baseline.rounds}');
  check('回测包含 6 个策略', report.reports.length == 6);
  check('随机基准平均命中红球在 0-6 之间',
      report.baseline.averageRedHits >= 0 && report.baseline.averageRedHits <= 6);


  print('== 预测多样性 ==');
  for (final strategy in SsqPredictStrategy.values) {
    final tickets = predictor.predict(draws, strategy: strategy, count: 8, random: Random(99));
    final keys = tickets.map((t) => t.redText + '|' + t.blueText).toSet();
    check('${strategy.label} 8 注互不相同', keys.length == tickets.length,
        '唯一 ${keys.length}/${tickets.length}');
    check('${strategy.label} 8 注均合法', tickets.every((t) =>
        t.reds.length == 6 && t.reds.toSet().length == 6 &&
        t.reds.every((e) => e >= 1 && e <= 33) &&
        t.blues.length == 1 && t.blues.first >= 1 && t.blues.first <= 16));
  }


  print('== 选号统计结构回读(按上游 int.parse 方式)==');
  final ssqDraws = <LotteryInfo>[];
  for (int i = 0; i < 40; i++) {
    final reds = List.generate(6, (k) => (k * 5 + i) % 33 + 1)
      ..sort()
      ..map((e) => e.toString().padLeft(2, '0'));
    ssqDraws.add(LotteryInfo.fromJson({
      'type': 'ssq',
      'period': '2026${(40 - i).toString().padLeft(3, '0')}',
      'red': reds.join(' '),
      'blue': '${((i % 16) + 1).toString().padLeft(2, '0')}',
      'shi': '',
      'kai': '',
      'lotDate': '2026/01/01',
      'com': '',
      'last': '',
      'lastDelta': 0,
    }));
  }
  final censusJson = LocalCensusCalculator.buildSsqJson(ssqDraws);
  final requiredKeys = ['r1', 'r2', 'r3', 'r12', 'r20', 'r25', 'rk3', 'rk6', 'b3', 'b5', 'bk'];
  bool keysOk = true;
  for (final k in requiredKeys) {
    if (censusJson[k] == null || censusJson[k]['values'] == null) {
      keysOk = false;
      print('  缺少字段: \$k');
    }
  }
  check('统计结构字段齐全', keysOk);
  // 上游 CensusValue.fromJson 用 int.parse 解析,值必须是字符串
  bool parseOk = true;
  for (final k in requiredKeys) {
    try {
      for (final row in censusJson[k]['values']) {
        for (final v in row) {
          int.parse(v);
        }
      }
    } catch (e) {
      parseOk = false;
      print('  \$k 解析失败: \$e');
    }
  }
  check('统计数值可被上游 int.parse 解析', parseOk);
  final r3 = censusJson['r3']['values'][0].map(int.parse).toList();
  check('r3 长度为 33', r3.length == 33, 'got \${r3.length}');
  final b5 = censusJson['b5']['values'][0].map(int.parse).toList();
  check('b5 长度为 16', b5.length == 16, 'got \${b5.length}');
  check('r3 计数在 0..3 之间', r3.every((e) => e >= 0 && e <= 3));
  check('rk6 计数在 0..6 之间', censusJson['rk6']['values'][0].map(int.parse).every((e) => e >= 0 && e <= 6));



  final dltJson = LocalCensusCalculator.buildDltJson(ssqDraws);
  final dltKeys = ['r2', 'r3', 'r10', 'r20', 'rk3', 'rk6', 'b2', 'b6', 'bk'];
  bool dltOk = true;
  for (final k in dltKeys) {
    if (dltJson[k] == null || dltJson[k]['values'] == null) {
      dltOk = false;
      print('  大乐透缺少字段: \$k');
    }
  }
  check('大乐透统计字段齐全', dltOk);
  bool dltParse = true;
  try {
    for (final k in dltKeys) {
      for (final row in dltJson[k]['values']) {
        for (final v in row) {
          int.parse(v);
        }
      }
    }
  } catch (e) {
    dltParse = false;
    print('  大乐透解析失败: \$e');
  }
  check('大乐透统计数值可被上游 int.parse 解析', dltParse);

  final qlcJson = LocalCensusCalculator.buildQlcJson(ssqDraws);
  final qlcKeys = ['r1', 'r2', 'r3', 'r12', 'r18', 'r22', 'k3', 'k6'];
  bool qlcOk = true;
  for (final k in qlcKeys) {
    if (qlcJson[k] == null || qlcJson[k]['values'] == null) {
      qlcOk = false;
      print('  七乐彩缺少字段: \$k');
    }
  }
  check('七乐彩统计字段齐全', qlcOk);


  print('');
  if (failures == 0) {
    print('全部通过');
  } else {
    print('失败 $failures 项');
  }
}

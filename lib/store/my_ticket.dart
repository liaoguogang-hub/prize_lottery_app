import 'dart:convert';

import 'package:get/get.dart';
import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';
import 'package:prize_lottery_app/data/ssq/ssq_history_store.dart';
import 'package:prize_lottery_app/data/ssq/ssq_prize_checker.dart';
import 'package:prize_lottery_app/utils/storage.dart';

///
/// 用户已购彩票记录
///
class MyTicket {
  ///
  /// 记录唯一标识
  ///
  final String id;

  ///
  /// 购买时的期号
  ///
  final String period;

  ///
  /// 投注红球
  ///
  final List<int> reds;

  ///
  /// 投注蓝球
  ///
  final List<int> blues;

  ///
  /// 胆码,胆拖玩法固定入选,其余为空
  ///
  final List<int> dan;

  ///
  /// 倍数
  ///
  final int multiple;

  ///
  /// 购买时间
  ///
  final DateTime boughtAt;

  ///
  /// 是否已核奖
  ///
  final bool checked;

  ///
  /// 中奖奖级,0 表示未中奖
  ///
  final int prizeLevel;

  ///
  /// 中奖金额(元)
  ///
  final int prizeAmount;

  ///
  /// 核奖时间
  ///
  final DateTime? checkedAt;

  ///
  /// 核奖时的开奖期号
  ///
  final String? drawPeriod;

  ///
  /// 命中红球个数
  ///
  final int hitRed;

  ///
  /// 是否命中蓝球
  ///
  final int hitBlue;

  MyTicket({
    required this.id,
    required this.period,
    required this.reds,
    required this.blues,
    this.dan = const [],
    this.multiple = 1,
    required this.boughtAt,
    this.checked = false,
    this.prizeLevel = 0,
    this.prizeAmount = 0,
    this.checkedAt,
    this.drawPeriod,
    this.hitRed = 0,
    this.hitBlue = 0,
  });

  ///
  /// 是否中奖
  ///
  bool get hit => prizeLevel > 0;

  ///
  /// 奖级名称
  ///
  String get prizeLevelName =>
      prizeLevel > 0 ? SsqPrizeChecker.levelNames[prizeLevel]! : '未中奖';

  ///
  /// 红球展示串
  ///
  String get redText =>
      reds.map((e) => e.toString().padLeft(2, '0')).join(' ');

  ///
  /// 蓝球展示串
  ///
  String get blueText =>
      blues.map((e) => e.toString().padLeft(2, '0')).join(' ');

  MyTicket copyWith({
    bool? checked,
    int? prizeLevel,
    int? prizeAmount,
    DateTime? checkedAt,
    String? drawPeriod,
    int? hitRed,
    int? hitBlue,
  }) {
    return MyTicket(
      id: id,
      period: period,
      reds: reds,
      blues: blues,
      dan: dan,
      multiple: multiple,
      boughtAt: boughtAt,
      checked: checked ?? this.checked,
      prizeLevel: prizeLevel ?? this.prizeLevel,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      checkedAt: checkedAt ?? this.checkedAt,
      drawPeriod: drawPeriod ?? this.drawPeriod,
      hitRed: hitRed ?? this.hitRed,
      hitBlue: hitBlue ?? this.hitBlue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'reds': reds,
      'blues': blues,
      'dan': dan,
      'multiple': multiple,
      'boughtAt': boughtAt.toIso8601String(),
      'checked': checked,
      'prizeLevel': prizeLevel,
      'prizeAmount': prizeAmount,
      'checkedAt': checkedAt?.toIso8601String(),
      'drawPeriod': drawPeriod,
      'hitRed': hitRed,
      'hitBlue': hitBlue,
    };
  }

  factory MyTicket.fromJson(Map<String, dynamic> json) {
    return MyTicket(
      id: '${json['id'] ?? ''}',
      period: '${json['period'] ?? ''}',
      reds: (json['reds'] as List?)
              ?.map((e) => int.tryParse('$e') ?? 0)
              .where((e) => e > 0)
              .toList() ??
          [],
      blues: (json['blues'] as List?)
              ?.map((e) => int.tryParse('$e') ?? 0)
              .where((e) => e > 0)
              .toList() ??
          [],
      dan: (json['dan'] as List?)
              ?.map((e) => int.tryParse('$e') ?? 0)
              .where((e) => e > 0)
              .toList() ??
          [],
      multiple: int.tryParse('${json['multiple'] ?? 1}') ?? 1,
      boughtAt:
          DateTime.tryParse('${json['boughtAt']}') ?? DateTime.now(),
      checked: json['checked'] == true,
      prizeLevel: int.tryParse('${json['prizeLevel'] ?? 0}') ?? 0,
      prizeAmount: int.tryParse('${json['prizeAmount'] ?? 0}') ?? 0,
      checkedAt: DateTime.tryParse('${json['checkedAt'] ?? ''}'),
      drawPeriod: json['drawPeriod']?.toString(),
      hitRed: int.tryParse('${json['hitRed'] ?? 0}') ?? 0,
      hitBlue: int.tryParse('${json['hitBlue'] ?? 0}') ?? 0,
    );
  }
}

///
/// 一次核奖的结果
///
class SsqCheckOutcome {
  ///
  /// 本次新中奖的记录
  ///
  final List<MyTicket> winners;

  ///
  /// 本次新开奖但未中奖的记录
  ///
  final List<MyTicket> losers;

  SsqCheckOutcome({required this.winners, required this.losers});

  ///
  /// 本次有结果的记录数
  ///
  int get total => winners.length + losers.length;

  ///
  /// 是否没有需要通知的新结果
  ///
  bool get isEmpty => total == 0;
}

///
/// 我的彩票仓库
///
/// 全部记录保存在本机,应用重启后依然存在
///
class MyTicketStore extends GetxController {
  ///
  /// 本地缓存键
  ///
  static const String cacheKey = 'my_tickets_v1';

  ///
  /// 全部记录,按购买时间倒序
  ///
  List<MyTicket> tickets = [];

  ///
  /// 未核奖的记录
  ///
  List<MyTicket> get pending => tickets.where((e) => !e.checked).toList();

  ///
  /// 已中奖的记录
  ///
  List<MyTicket> get winners => tickets.where((e) => e.hit).toList();

  ///
  /// 累计中奖金额
  ///
  int get totalPrize =>
      tickets.fold(0, (sum, e) => sum + e.prizeAmount);

  ///
  /// 从本地缓存加载
  ///
  void initialize() {
    List<Map>? cached = Storage().getObjectList(cacheKey);
    if (cached != null) {
      tickets = cached
          .map((e) => MyTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.boughtAt.compareTo(a.boughtAt));
    }
    update();
  }

  ///
  /// 新增一条已购记录
  ///
  void add({
    required String period,
    required List<int> reds,
    required List<int> blues,
    List<int> dan = const [],
    int multiple = 1,
    String? id,
  }) {
    MyTicket ticket = MyTicket(
      id: id ??
          '${DateTime.now().microsecondsSinceEpoch}-${reds.join('-')}-${blues.join('-')}',
      period: period,
      reds: reds,
      blues: blues,
      dan: dan,
      multiple: multiple,
      boughtAt: DateTime.now(),
    );
    tickets.insert(0, ticket);
    _persist();
    update();
  }

  ///
  /// 删除一条记录
  ///
  void remove(String id) {
    tickets.removeWhere((e) => e.id == id);
    _persist();
    update();
  }

  ///
  /// 清空全部记录
  ///
  void clear() {
    tickets.clear();
    _persist();
    update();
  }

  ///
  /// 用历史开奖数据核奖
  ///
  /// 返回本次的核奖结果
  ///
  SsqCheckOutcome check(SsqHistoryStore history) {
    SsqPrizeChecker checker = SsqPrizeChecker();
    List<MyTicket> newWinners = [];
    List<MyTicket> newLosers = [];
    List<MyTicket> result = [];
    for (final ticket in tickets) {
      if (ticket.checked) {
        result.add(ticket);
        continue;
      }
      SsqDraw? draw = _findDraw(history, ticket.period);
      if (draw == null) {
        result.add(ticket);
        continue;
      }
      SsqPrizeResult prize = checker.check(
        ticketReds: ticket.reds,
        ticketBlues: ticket.blues,
        dan: ticket.dan,
        drawReds: draw.reds,
        drawBlue: draw.blue,
        firstPrize: _gradeAmount(draw, 1),
        secondPrize: _gradeAmount(draw, 2),
      );
      MyTicket updated = ticket.copyWith(
        checked: true,
        prizeLevel: prize.level,
        prizeAmount: prize.amount * ticket.multiple,
        checkedAt: DateTime.now(),
        drawPeriod: draw.period,
        hitRed: prize.hitRed,
        hitBlue: prize.hitBlue,
      );
      if (updated.hit) {
        newWinners.add(updated);
      } else {
        newLosers.add(updated);
      }
      result.add(updated);
    }
    tickets = result..sort((a, b) => b.boughtAt.compareTo(a.boughtAt));
    _persist();
    update();
    return SsqCheckOutcome(winners: newWinners, losers: newLosers);
  }

  ///
  /// 找到期号对应的开奖记录
  ///
  /// 期号为空时取最新一期,期号小于最新期号时同样取最新一期
  ///
  SsqDraw? _findDraw(SsqHistoryStore history, String period) {
    if (history.draws.isEmpty) {
      return null;
    }
    if (period.isEmpty) {
      return history.latest;
    }
    SsqDraw? exact = history.byPeriod(period);
    if (exact != null) {
      return exact;
    }
    ///
    /// 购买的期号尚未开奖时,不核奖
    ///
    return null;
  }

  ///
  /// 取当期某奖级的单注奖金
  ///
  int _gradeAmount(SsqDraw draw, int type) {
    for (final grade in draw.grades) {
      if (grade.type == type) {
        return grade.money;
      }
    }
    return 0;
  }

  ///
  /// 写入本地缓存
  ///
  void _persist() {
    Storage().putObjectList(cacheKey, tickets.map((e) => e.toJson()).toList());
  }

  ///
  /// 导出为 JSON 字符串,便于备份
  ///
  String exportJson() {
    return json.encode(tickets.map((e) => e.toJson()).toList());
  }
}

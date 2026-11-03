import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';
import 'package:prize_lottery_app/data/ssq/ssq_official_api.dart';
import 'package:prize_lottery_app/utils/storage.dart';

///
/// 双色球历史开奖数据仓库
///
/// 数据来源为预置的历史数据资产与福彩官网开奖接口,二者合并后按期号倒序缓存到本地
///
class SsqHistoryStore extends GetxController {
  ///
  /// 本地缓存键
  ///
  static const String cacheKey = 'ssq_history_cache_v1';

  ///
  /// 预置历史数据资产路径
  ///
  static const String assetPath = 'assets/data/ssq_history.json';

  ///
  /// 开奖记录,按期号倒序,index 0 为最新一期
  ///
  List<SsqDraw> draws = [];

  ///
  /// 是否已完成初始化
  ///
  bool get ready => draws.isNotEmpty;

  ///
  /// 最新一期开奖
  ///
  SsqDraw? get latest => draws.isEmpty ? null : draws.first;

  ///
  /// 最新期号
  ///
  String get latestPeriod => latest?.period ?? '';

  ///
  /// 下一期期号
  ///
  /// 双色球每年 153 期,跨年时年份加一、期号归 001
  ///
  String get nextPeriod {
    String period = latestPeriod;
    if (period.length < 7) {
      return period;
    }
    int year = int.tryParse(period.substring(0, 4)) ?? 0;
    int seq = int.tryParse(period.substring(4)) ?? 0;
    if (seq >= 153) {
      return '${year + 1}001';
    }
    return '$year${(seq + 1).toString().padLeft(3, '0')}';
  }

  ///
  /// 加载预置数据与本地缓存
  ///
  Future<void> initialize() async {
    List<SsqDraw> merged = [];

    ///
    /// 先读本地缓存
    ///
    List<Map>? cached = Storage().getObjectList(cacheKey);
    if (cached != null) {
      for (final item in cached) {
        merged.add(SsqDraw.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    ///
    /// 再读预置资产,用于首次安装补齐历史
    ///
    if (merged.length < 100) {
      try {
        String raw = await rootBundle.loadString(assetPath);
        final decoded = json.decode(raw);
        List<Map<String, dynamic>> bundled = decoded is Map
            ? (decoded['draws'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : (decoded as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        for (final item in bundled) {
          merged.add(SsqDraw.fromJson(item));
        }
      } catch (e) {
        ///
        /// 资产缺失时不影响联网获取
        ///
      }
    }

    _sortAndDedupe(merged);
    _persist();
  }

  ///
  /// 从福彩官网拉取最新开奖并合并入库
  ///
  /// 返回是否有新增数据
  ///
  Future<bool> refreshHistory({int issueCount = 60}) async {
    try {
      List<SsqDraw> fresh = await SsqOfficialApi().fetchHistory(
        issueCount: issueCount,
      );
      if (fresh.isEmpty) {
        return false;
      }
      Map<String, SsqDraw> merged = {};
      for (final draw in draws) {
        merged[draw.period] = draw;
      }
      bool changed = false;
      for (final draw in fresh) {
        if (!merged.containsKey(draw.period)) {
          merged[draw.period] = draw;
          changed = true;
        }
      }
      List<SsqDraw> list = merged.values.toList();
      _sortAndDedupe(list);
      _persist();
      return changed;
    } catch (e) {
      return false;
    }
  }

  ///
  /// 按期号查询开奖记录
  ///
  SsqDraw? byPeriod(String period) {
    for (final draw in draws) {
      if (draw.period == period) {
        return draw;
      }
    }
    return null;
  }

  ///
  /// 取最近若干期
  ///
  List<SsqDraw> recent(int count) {
    return draws.take(count).toList();
  }

  ///
  /// 排序并按期号去重
  ///
  void _sortAndDedupe(List<SsqDraw> list) {
    Map<String, SsqDraw> unique = {};
    for (final draw in list) {
      if (draw.period.isEmpty) {
        continue;
      }
      unique[draw.period] = draw;
    }
    List<SsqDraw> result = unique.values.toList()
      ..sort((a, b) => b.period.compareTo(a.period));
    draws = result;
    update();
  }

  ///
  /// 写入本地缓存
  ///
  void _persist() {
    List<Map> list = draws.map((e) => e.toJson()).toList();
    Storage().putObjectList(cacheKey, list);
  }
}

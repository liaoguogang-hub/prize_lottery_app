import 'package:flutter/widgets.dart';
import 'package:prize_lottery_app/app/notification_service.dart';
import 'package:prize_lottery_app/data/ssq/ssq_history_store.dart';
import 'package:prize_lottery_app/store/my_ticket.dart';
import 'package:prize_lottery_app/utils/storage.dart';
import 'package:workmanager/workmanager.dart';

///
/// 核奖周期任务名
///
const String ssqPrizeTaskName = 'ssq_prize_check';

///
/// 定期核奖调度器
///
/// 通过 WorkManager 注册 Android 周期任务,应用退到后台后仍会定期拉取开奖结果,
/// 比对用户已购彩票并通过本地通知告知用户是否中奖
///
class PrizeWatcher {
  ///
  /// 初始化通知与周期任务
  ///
  static Future<void> initialize() async {
    await NotificationService.initialize();
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        ssqPrizeTaskName,
        ssqPrizeTaskName,
        frequency: const Duration(hours: 2),
        initialDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      ///
      /// 部分设备不支持后台任务时静默降级为前台检查
      ///
    }
  }

  ///
  /// 立即执行一次核奖检查
  ///
  /// 返回本次核奖结果
  ///
  static Future<SsqCheckOutcome> checkNow({bool notify = true}) async {
    await Storage().initialize();
    SsqHistoryStore history = SsqHistoryStore();
    await history.initialize();
    await history.refreshHistory();

    MyTicketStore store = MyTicketStore();
    store.initialize();
    if (store.tickets.isEmpty) {
      return SsqCheckOutcome(winners: [], losers: []);
    }

    SsqCheckOutcome outcome = store.check(history);
    if (notify && !outcome.isEmpty) {
      await _notify(outcome);
    }
    return outcome;
  }

  ///
  /// 发送核奖结果通知
  ///
  static Future<void> _notify(SsqCheckOutcome outcome) async {
    if (outcome.winners.isNotEmpty) {
      int amount = outcome.winners.fold(0, (sum, e) => sum + e.prizeAmount);
      String levels = outcome.winners.map((e) => e.prizeLevelName).toSet().join('、');
      await NotificationService.showPrizeResult(
        id: 1001,
        title: '恭喜中奖!${levels}',
        body: '共 ${outcome.winners.length} 注中奖,奖金合计 ${amount} 元,快去核对吧',
      );
    }
    if (outcome.losers.isNotEmpty) {
      await NotificationService.showPrizeResult(
        id: 1002,
        title: '本期开奖已核对',
        body: '${outcome.losers.length} 注彩票未中奖,继续加油',
      );
    }
  }
}

///
/// 后台任务回调入口
///
/// 必须为顶层函数并标注 vm:entry-point,后台 isolate 才能找到
///
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    try {
      await PrizeWatcher.checkNow();
    } catch (e) {
      ///
      /// 后台任务失败不重试,下一周期再检查
      ///
    }
    return true;
  });
}

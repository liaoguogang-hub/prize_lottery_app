import 'package:get/get.dart';
import 'package:prize_lottery_app/app/notification_service.dart';
import 'package:prize_lottery_app/app/prize_watcher.dart';
import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';
import 'package:prize_lottery_app/data/ssq/ssq_history_store.dart';
import 'package:prize_lottery_app/data/ssq/ssq_predictor.dart';
import 'package:prize_lottery_app/data/ssq/ssq_random_picker.dart';
import 'package:prize_lottery_app/store/my_ticket.dart';

///
/// 双色球助手控制器
///
/// 聚合机选、预测、开奖历史与我的彩票四个模块
///
class SsqAssistantController extends GetxController {
  ///
  /// 历史开奖仓库
  ///
  final SsqHistoryStore history = SsqHistoryStore();

  ///
  /// 我的彩票仓库
  ///
  final MyTicketStore myTickets = MyTicketStore();

  ///
  /// 预测器
  ///
  final SsqPredictor predictor = SsqPredictor();

  ///
  /// 机选器
  ///
  final SsqRandomPicker picker = SsqRandomPicker();

  ///
  /// 机选生成的号码
  ///
  List<SsqTicket> randomTickets = [];

  ///
  /// 预测生成的号码
  ///
  List<SsqTicket> predictedTickets = [];

  ///
  /// 当前预测策略
  ///
  SsqPredictStrategy strategy = SsqPredictStrategy.ensemble;

  ///
  /// 回测报告
  ///
  SsqBacktestReport? backtestReport;

  ///
  /// 是否正在加载
  ///
  bool loading = false;

  ///
  /// 统计窗口
  ///
  int window = SsqPredictor.defaultWindow;

  @override
  void onInit() {
    super.onInit();
    history.initialize().then((_) {
      myTickets.initialize();
      refreshHistory();
      generateRandom();
      update();
    });
    NotificationService.requestPermission();
  }

  ///
  /// 刷新开奖数据
  ///
  Future<void> refreshHistory() async {
    loading = true;
    update();
    await history.refreshHistory();
    loading = false;
    update();
  }

  ///
  /// 机选生成号码
  ///
  void generateRandom({int count = 5}) {
    randomTickets = picker.batch(count);
    update();
  }

  ///
  /// 生成预测号码
  ///
  void generatePrediction({int count = 5}) {
    predictedTickets = predictor.predict(
      history.draws,
      strategy: strategy,
      window: window,
      count: count,
    );
    update();
  }

  ///
  /// 运行回测
  ///
  void runBacktest({int rounds = 100}) {
    backtestReport = predictor.backtest(
      history.draws,
      rounds: rounds,
      window: window,
    );
    update();
  }

  ///
  /// 切换预测策略
  ///
  void changeStrategy(SsqPredictStrategy value) {
    strategy = value;
    generatePrediction();
  }

  ///
  /// 确认购买,把号码存入我的彩票
  ///
  /// [multiple] 为投注倍数
  ///
  void confirmPurchase(SsqTicket ticket, {int multiple = 1}) {
    myTickets.add(
      period: history.nextPeriod,
      reds: ticket.reds,
      blues: ticket.blues,
      dan: ticket.dan,
      multiple: multiple,
    );
    update();
  }

  ///
  /// 立即核奖一次
  ///
  Future<SsqCheckOutcome> checkNow() async {
    SsqCheckOutcome outcome = await PrizeWatcher.checkNow();
    myTickets.initialize();
    update();
    return outcome;
  }

  ///
  /// 最近开奖记录
  ///
  List<SsqDraw> get recentDraws => history.recent(30);
}

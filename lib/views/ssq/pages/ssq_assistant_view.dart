import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:prize_lottery_app/data/ssq/ssq_predictor.dart';
import 'package:prize_lottery_app/data/ssq/ssq_random_picker.dart';
import 'package:prize_lottery_app/resources/styles.dart';
import 'package:prize_lottery_app/views/ssq/controller/ssq_assistant_controller.dart';
import 'package:prize_lottery_app/views/ssq/pages/my_ticket_view.dart';
import 'package:prize_lottery_app/views/ssq/widgets/ssq_balls.dart';

///
/// 双色球助手主页
///
/// 包含机选、预测、开奖历史、我的彩票四个模块
///
class SsqAssistantView extends StatefulWidget {
  const SsqAssistantView({super.key});

  @override
  State<SsqAssistantView> createState() => _SsqAssistantViewState();
}

class _SsqAssistantViewState extends State<SsqAssistantView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SsqAssistantController>()) {
      Get.put<SsqAssistantController>(SsqAssistantController());
    }
    return AnnotatedRegion(
      value: UiStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF0033),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('双色球助手', style: TextStyle(fontSize: 17)),
          actions: [
            GetBuilder<SsqAssistantController>(builder: (controller) {
              return IconButton(
                tooltip: '刷新开奖数据',
                onPressed: controller.loading
                    ? null
                    : () => controller.refreshHistory(),
                icon: const Icon(Icons.refresh),
              );
            }),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontSize: 14),
            tabs: const [
              Tab(text: '机选'),
              Tab(text: '预测'),
              Tab(text: '开奖'),
              Tab(text: '我的彩票'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _RandomPanel(),
            _ForecastPanel(),
            _DrawPanel(),
            MyTicketView(),
          ],
        ),
      ),
    );
  }
}

///
/// 机选面板
///
class _RandomPanel extends StatelessWidget {
  const _RandomPanel();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SsqAssistantController>(builder: (controller) {
      return ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          _card(
            title: '随机机选',
            subtitle: '红球从 01-33 无放回抽取 6 个,蓝球从 01-16 抽取 1 个',
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0033),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                    ),
                    onPressed: () => controller.generateRandom(count: 5),
                    child: const Text('重新机选 5 注', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF0033),
                      side: const BorderSide(color: Color(0xFFFF0033)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                    ),
                    onPressed: () => controller.generateRandom(count: 10),
                    child: const Text('机选 10 注'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          ...controller.randomTickets.map((ticket) => _ticketCard(controller, ticket)),
        ],
      );
    });
  }
}

///
/// 预测面板
///
class _ForecastPanel extends StatelessWidget {
  const _ForecastPanel();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SsqAssistantController>(builder: (controller) {
      return ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          _card(
            title: '预测策略',
            subtitle: '全部基于本机历史开奖数据计算,未使用任何服务端接口',
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.w,
              children: SsqPredictStrategy.values.map((strategy) {
                bool active = controller.strategy == strategy;
                return GestureDetector(
                  onTap: () => controller.changeStrategy(strategy),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.w),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFF0033) : const Color(0xFFF2F2F6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      strategy.label,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF555555),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12.w),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0033),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.w),
                    ),
                  ),
                  onPressed: () => controller.generatePrediction(),
                  child: const Text('生成推荐号码', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF0033),
                    side: const BorderSide(color: Color(0xFFFF0033)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.w),
                    ),
                  ),
                  onPressed: () => controller.runBacktest(),
                  child: const Text('策略回测'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          ...controller.predictedTickets.map((ticket) => _ticketCard(controller, ticket)),
          if (controller.backtestReport != null) ...[
            SizedBox(height: 12.w),
            _backtestCard(controller.backtestReport!),
          ],
        ],
      );
    });
  }
}

///
/// 开奖历史面板
///
class _DrawPanel extends StatelessWidget {
  const _DrawPanel();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SsqAssistantController>(builder: (controller) {
      return ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          _card(
            title: '开奖数据',
            subtitle: controller.history.ready
                ? '本机已缓存 ${controller.history.draws.length} 期历史开奖,数据源:中国福利彩票官方接口'
                : '正在加载历史开奖数据',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '最新期号 ${controller.history.latestPeriod} · 下一期 ${controller.history.nextPeriod}',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                if (controller.loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          ...controller.recentDraws.map((draw) => Container(
                margin: EdgeInsets.only(bottom: 10.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '第 ${draw.period} 期',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          draw.date.toString().substring(0, 10),
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    SsqBalls(reds: draw.reds, blues: [draw.blue]),
                    SizedBox(height: 6.w),
                    Text(
                      '销售额 ${(draw.sales / 10000).toStringAsFixed(0)} 万元 · 奖池 ${(draw.poolMoney / 100000000).toStringAsFixed(2)} 亿元',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              )),
        ],
      );
    });
  }
}

///
/// 号码卡片
///
Widget _ticketCard(SsqAssistantController controller, SsqTicket ticket) {
  return Container(
    margin: EdgeInsets.only(bottom: 10.w),
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SsqBalls(reds: ticket.reds, blues: ticket.blues),
        SizedBox(height: 10.w),
        Row(
          children: [
            Expanded(
              child: Text(
                '预计 ${controller.history.nextPeriod} 期 · 2 元/注',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
            GestureDetector(
              onTap: () {
                controller.confirmPurchase(ticket);
                Get.snackbar(
                  '已记录',
                  '已存入我的彩票,开奖后会自动核奖并通知你',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFFFF0033),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(12),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0033),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  '我已购买',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

///
/// 回测结果卡片
///
Widget _backtestCard(SsqBacktestReport report) {
  return Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '滚动回测结果',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4.w),
        Text(
          '回测 ${report.baseline.rounds} 期,逐期用当时可见的数据生成号码与真实开奖比对',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        SizedBox(height: 10.w),
        _backtestRow('随机基准', report.baseline.hitRate, report.baseline.averageRedHits, true),
        ...report.reports.map((e) => _backtestRow(e.strategy.label, e.hitRate, e.averageRedHits, false)),
        SizedBox(height: 8.w),
        Text(
          report.beatsBaseline
              ? '注: 双色球为独立随机事件,中奖率高于基准通常来自样本波动,不代表长期优势。'
              : '注: 所有策略的中奖率均未超过随机基准,双色球每期独立同分布,历史数据无法预测下期。',
          style: const TextStyle(fontSize: 11, color: Color(0xFF999999), height: 1.5),
        ),
      ],
    ),
  );
}

Widget _backtestRow(String label, double hitRate, double redHits, bool baseline) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 3.w),
    child: Row(
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: baseline ? const Color(0xFFFF0033) : Colors.black87,
              fontWeight: baseline ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '中奖率 ${(hitRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Text(
          '平均命中 ${redHits.toStringAsFixed(2)} 红',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    ),
  );
}

///
/// 通用卡片
///
Widget _card({
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.w),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
          ),
        ],
        SizedBox(height: 12.w),
        child,
      ],
    ),
  );
}

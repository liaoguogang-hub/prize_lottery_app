import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:prize_lottery_app/routes/names.dart';

///
/// 本地选号工具入口
///
/// 上游「专家」页展示的是服务端上的专家账号及其推荐方案,服务端下线后没有可用数据。
/// 这里改为聚合各彩种**完全本地可用**的分析工具,保证该页签有实际内容。
///
class LocalToolEntry {
  ///
  /// 工具名称
  ///
  final String title;

  ///
  /// 图标资源名
  ///
  final String icon;

  ///
  /// 目标路由
  ///
  final String route;

  const LocalToolEntry({
    required this.title,
    required this.icon,
    required this.route,
  });
}

///
/// 各彩种的本地工具
///
/// key 为彩种类型,value 为工具列表
///
const Map<String, List<LocalToolEntry>> localLotteryTools = {
  'ssq': [
    LocalToolEntry(
        title: '综合分析',
        icon: 'zonghe_analyze_icon',
        route: AppRoutes.ssqVipCensus),
    LocalToolEntry(
        title: '号码走势',
        icon: 'trend_analyze_icon',
        route: '/ssq/trend/0'),
    LocalToolEntry(
        title: '缩水过滤', icon: 'filter_analyze_icon', route: AppRoutes.ssqShrink),
    LocalToolEntry(
        title: '奖金计算', icon: 'calc_analyze_icon', route: AppRoutes.ssqCalculator),
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/ssq'),
  ],
  'dlt': [
    LocalToolEntry(
        title: '综合分析',
        icon: 'zonghe_analyze_icon',
        route: AppRoutes.dltVipCensus),
    LocalToolEntry(
        title: '号码走势',
        icon: 'trend_analyze_icon',
        route: '/dlt/trend/0'),
    LocalToolEntry(
        title: '缩水过滤', icon: 'filter_analyze_icon', route: AppRoutes.dltShrink),
    LocalToolEntry(
        title: '奖金计算', icon: 'calc_analyze_icon', route: AppRoutes.dltCalculator),
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/dlt'),
  ],
  'qlc': [
    LocalToolEntry(
        title: '综合分析',
        icon: 'zonghe_analyze_icon',
        route: AppRoutes.qlcVipCensus),
    LocalToolEntry(
        title: '号码走势',
        icon: 'trend_analyze_icon',
        route: '/qlc/trend/0'),
    LocalToolEntry(
        title: '缩水过滤', icon: 'filter_analyze_icon', route: AppRoutes.qlcShrink),
    LocalToolEntry(
        title: '奖金计算', icon: 'calc_analyze_icon', route: AppRoutes.qlcCalculator),
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/qlc'),
  ],
  'fc3d': [
    LocalToolEntry(
        title: '缩水过滤', icon: 'filter_analyze_icon', route: AppRoutes.fc3dShrink),
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/fc3d'),
  ],
  'pl3': [
    LocalToolEntry(
        title: '缩水过滤', icon: 'filter_analyze_icon', route: AppRoutes.pl3Shrink),
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/pl3'),
  ],
  'pl5': [
    LocalToolEntry(
        title: '历史开奖', icon: 'history_analyze_icon', route: '/lotto/history/pl5'),
  ],
};

///
/// 彩种名称与图标
///
const Map<String, List<String>> localLotteryMeta = {
  'ssq': ['双色球', 'ssq_icon'],
  'dlt': ['大乐透', 'dlt_icon'],
  'qlc': ['七乐彩', 'qlc_icon'],
  'fc3d': ['福彩3D', 'fc3d_icon'],
  'pl3': ['排列三', 'pl3_icon'],
};

///
/// 全部工具(按彩种分组)
///
class LocalToolsView extends StatelessWidget {
  const LocalToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 24.w),
      children: localLotteryMeta.keys.map((type) {
        List<String> meta = localLotteryMeta[type]!;
        List<LocalToolEntry> tools = localLotteryTools[type]!;
        return Container(
          margin: EdgeInsets.only(bottom: 12.w),
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
                  ClipOval(
                    child: Image.asset(
                      'assets/images/icons/${meta[1]}.png',
                      width: 26.w,
                      height: 26.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    meta[0],
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.w),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.w,
                children: tools.map((e) => _toolCell(e)).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

///
/// 单个彩种的工具列表
///
class LotteryToolsView extends StatelessWidget {
  const LotteryToolsView({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    List<LocalToolEntry> tools = localLotteryTools[type] ?? const [];
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 24.w),
      children: tools.map((e) => _toolCell(e, full: true)).toList(),
    );
  }
}

///
/// 工具入口单元格
///
Widget _toolCell(LocalToolEntry entry, {bool full = false}) {
  Widget cell = GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      Get.toNamed(entry.route);
    },
    child: Container(
      width: full ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/icons/${entry.icon}.png',
              width: 22.w,
              height: 22.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            entry.title,
            style: TextStyle(fontSize: 13.sp, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
  return cell;
}

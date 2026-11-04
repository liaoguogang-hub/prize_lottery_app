import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prize_lottery_app/widgets/layout_container.dart';

///
/// 使用指南
///
/// 上游该页面是加载 CDN 上的 HTML,`icaiwa.com` 已下线,改为随包内置的说明内容
///
class LocalManualView extends StatelessWidget {
  const LocalManualView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutContainer(
      title: '使用指南',
      content: ListView(
        padding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 32.w),
        children: [
          _section('关于本应用', [
            '本应用基于开源项目 prize_lottery_app 二次开发。原工程的服务端已停止服务,'
                '当前版本改为完全离线运行:开奖数据直连中国福彩与中国体彩官方接口,'
                '分析与预测全部在本机计算。',
            '不需要注册账号,数据保存在本机。',
          ]),
          _section('开奖数据从哪来', [
            '中国福彩官网(cwl.gov.cn):双色球、福彩3D、七乐彩、快乐8',
            '中国体彩官网(webapi.sporttery.cn):大乐透、排列三、排列五',
            '所有号码、奖级、销售额与奖池均为官方公布数据。',
          ]),
          _section('双色球助手(底部「助手」页签)', [
            '机选:红球 01-33 无放回抽取 6 个,蓝球 01-16 抽取 1 个;'
                '支持单式、复式与胆拖。',
            '预测:提供热号追随、冷号逆向、遗漏回归、均衡分布、均值回归、综合集成六种策略,'
                '每注号码按策略权重加权抽样,多注结果互不相同。',
            '策略回测:用每一期之前的数据生成号码,与真实开奖比对,并给出随机基准作为对照。',
            '开奖:内置 2084 期历史开奖,可联网增量更新。',
            '我的彩票:点「我已购买」把号码存入本机,开奖后自动核奖。',
          ]),
          _section('自动核奖与提醒', [
            '在「我的彩票」页点「开启通知」授权后,应用会每两小时在后台拉取一次开奖结果,'
                '自动比对已购彩票并通过通知告知是否中奖。',
            '部分手机的系统省电策略会限制后台任务,此时可回到应用内点「立即核奖」手动核对。',
          ]),
          _section('奖级判定规则', [
            '一等奖 6+1(浮动)· 二等奖 6+0(浮动)',
            '三等奖 5+1(3000 元)· 四等奖 5+0 或 4+1(200 元)',
            '五等奖 4+0 或 3+1(10 元)· 六等奖 2+1 / 1+1 / 0+1(5 元)',
            '复式与胆拖按组合数精确计算各奖级注数,不做逐注枚举。',
          ]),
          _section('分析工具(首页与「专家」页签)', [
            '综合分析:按最近 3/12/20/25 期的出现频次给出推荐热度,'
                '按最近 3/6 期的未出现次数给出杀号热度。',
            '号码走势:逐号码的遗漏与分布走势,含最大遗漏、平均遗漏、出现次数、最大连出。',
            '缩水过滤:按胆码、和值、形态、AC 值、质合、012 路、跨度、分区等条件筛选号码。',
            '奖金计算:按复式、胆拖的注数与奖级计算命中金额。',
            '历史开奖:按期查看开奖号码与当期和值、奇偶、质合、跨度、连号。',
          ]),
          _section('重要提示', [
            '彩票每期开奖相互独立,历史数据无法提高中奖概率。'
                '应用内的回测结果会如实展示各策略与随机基准的对比。',
            '本应用不提供购彩服务,请理性购彩。',
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<String> paragraphs) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.w),
          ...paragraphs.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 6.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 5.w, right: 6.w),
                      child: Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0033),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

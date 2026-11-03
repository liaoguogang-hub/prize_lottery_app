import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:prize_lottery_app/app/notification_service.dart';
import 'package:prize_lottery_app/store/my_ticket.dart';
import 'package:prize_lottery_app/views/ssq/controller/ssq_assistant_controller.dart';
import 'package:prize_lottery_app/views/ssq/widgets/ssq_balls.dart';

///
/// 我的彩票
///
/// 展示用户确认购买的彩票与自动核奖结果
///
class MyTicketView extends StatelessWidget {
  const MyTicketView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SsqAssistantController>(builder: (controller) {
      MyTicketStore store = controller.myTickets;
      return ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0033), Color(0xFFFF6B81)],
              ),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Row(
              children: [
                _stat('${store.tickets.length}', '全部记录'),
                _stat('${store.pending.length}', '待开奖'),
                _stat('${store.winners.length}', '已中奖'),
                _stat('${store.totalPrize}', '累计奖金(元)'),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '自动核奖提醒',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.w),
                const Text(
                  '开启后应用会定期拉取开奖结果,自动比对已购彩票并通知你',
                  style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
                ),
                SizedBox(height: 10.w),
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
                        onPressed: () async {
                          bool granted = await NotificationService.requestPermission();
                          Get.snackbar(
                            granted ? '已开启' : '未开启',
                            granted ? '开奖后会通过通知告诉你是否中奖' : '请到系统设置中允许本应用发送通知',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFFFF0033),
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(12),
                          );
                        },
                        child: const Text('开启通知', style: TextStyle(color: Colors.white)),
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
                        onPressed: () async {
                          SsqCheckOutcome outcome = await controller.checkNow();
                          Get.snackbar(
                            '核奖完成',
                            outcome.total == 0
                                ? '没有需要核对的彩票'
                                : '新增结果 ${outcome.total} 注,中奖 ${outcome.winners.length} 注',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFFFF0033),
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(12),
                          );
                        },
                        child: const Text('立即核奖'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.w),
          if (store.tickets.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 40.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: const Center(
                child: Text(
                  '还没有购买记录,去机选或预测页选几注号码吧',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ),
            )
          else
            ...store.tickets.map((ticket) => _ticketItem(ticket)),
        ],
      );
    });
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.w),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

Widget _ticketItem(MyTicket ticket) {
  Color statusColor = ticket.hit
      ? const Color(0xFFFF0033)
      : (ticket.checked ? Colors.black45 : const Color(0xFF3F7FD8));
  String statusText = ticket.hit
      ? '${ticket.prizeLevelName} ${ticket.prizeAmount} 元'
      : (ticket.checked ? '未中奖' : '待开奖');
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
        Row(
          children: [
            Text(
              '第 ${ticket.period} 期',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8.w),
            Text(
              '${ticket.boughtAt.toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const Spacer(),
            Text(
              statusText,
              style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 10.w),
        SsqBalls(reds: ticket.reds, blues: ticket.blues),
        SizedBox(height: 8.w),
        Row(
          children: [
            Text(
              ticket.checked
                  ? '命中 ${ticket.hitRed} 红 ${ticket.hitBlue > 0 ? '+ 1 蓝' : ''}'
                  : '${ticket.multiple} 倍 · 预计 ${ticket.reds.length > 6 ? ticket.reds.length * (ticket.blues.length) : 1} 注',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Get.find<SsqAssistantController>().myTickets.remove(ticket.id);
              },
              child: const Text(
                '删除',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

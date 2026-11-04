import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:prize_lottery_app/store/browse_history.dart';
import 'package:prize_lottery_app/widgets/layout_container.dart';

///
/// 浏览历史
///
/// 上游的浏览记录由服务端提供,服务端下线后改为读取本机记录
///
class LocalBrowseView extends StatelessWidget {
  const LocalBrowseView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutContainer(
      title: '浏览历史',
      content: GetBuilder<BrowseHistoryStore>(
        init: BrowseHistoryStore(),
        initState: (_) => BrowseHistoryStore().initialize(),
        builder: (store) {
          if (store.entries.isEmpty) {
            return Center(
              child: Text(
                '还没有浏览记录',
                style: TextStyle(fontSize: 14.sp, color: Colors.black38),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 24.w),
                  itemCount: store.entries.length,
                  itemBuilder: (context, index) {
                    BrowseEntry entry = store.entries[index];
                    return _buildItem(store, entry);
                  },
                ),
              ),
              _buildFooter(store),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(BrowseHistoryStore store, BrowseEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.w),
        onTap: () {
          if (entry.path.isNotEmpty) {
            Get.toNamed(entry.path);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      _timeText(entry.time),
                      style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  store.remove(entry.path);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    '删除',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BrowseHistoryStore store) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      width: double.infinity,
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          store.clear();
        },
        child: Text(
          '清空浏览历史',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFFFF0033)),
        ),
      ),
    );
  }

  ///
  /// 相对时间描述
  ///
  String _timeText(DateTime time) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(time);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24 && now.day == time.day) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    }
    return '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
  }
}

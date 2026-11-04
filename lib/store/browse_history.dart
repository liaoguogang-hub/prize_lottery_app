import 'package:get/get.dart';
import 'package:prize_lottery_app/utils/storage.dart';

///
/// 单条浏览记录
///
class BrowseEntry {
  ///
  /// 页面路由
  ///
  final String path;

  ///
  /// 页面标题
  ///
  final String title;

  ///
  /// 浏览时间
  ///
  final DateTime time;

  BrowseEntry({required this.path, required this.title, required this.time});

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'title': title,
      'time': time.toIso8601String(),
    };
  }

  factory BrowseEntry.fromJson(Map<String, dynamic> json) {
    return BrowseEntry(
      path: '${json['path'] ?? ''}',
      title: '${json['title'] ?? ''}',
      time: DateTime.tryParse('${json['time']}') ?? DateTime.now(),
    );
  }
}

///
/// 本地浏览历史
///
/// 上游的浏览记录由服务端存储,服务端下线后改为本机记录:
/// 由路由回调写入,列表页直接读取。
///
class BrowseHistoryStore extends GetxController {
  ///
  /// 存储键
  ///
  static const String cacheKey = 'browse_history_list_v1';

  ///
  /// 最多保存条数
  ///
  static const int maxEntries = 200;

  ///
  /// 路由到中文标题的映射
  ///
  static const Map<String, String> routeTitles = {
    '/main': '',
    '/ssq/assistant': '双色球助手',
    '/browse': '浏览历史',
    '/manual_book': '使用指南',
    '/settings': '设置',
    '/sign': '签到活动',
    '/ssq/vip/census': '双色球综合分析',
    '/dlt/vip/census': '大乐透综合分析',
    '/qlc/vip/census': '七乐彩综合分析',
    '/ssq/shrink': '双色球缩水过滤',
    '/dlt/shrink': '大乐透缩水过滤',
    '/qlc/shrink': '七乐彩缩水过滤',
    '/fc3d/shrink': '福彩3D缩水过滤',
    '/pl3/shrink': '排列三缩水过滤',
    '/ssq/calculator': '双色球奖金计算',
    '/dlt/calculator': '大乐透奖金计算',
    '/qlc/calculator': '七乐彩奖金计算',
    '/ssq/battle': '双色球专家PK',
    '/ssq/rate/census': '双色球臻选牛人',
    '/ssq/full/census': '双色球整体分析',
  };

  ///
  /// 动态路由(含参数)的标题规则
  ///
  static const List<List<String>> routePatterns = [
    ['/lotto/history/', '历史开奖'],
    ['/lotto/detail/', '开奖详情'],
    ['/ssq/trend/', '双色球号码走势'],
    ['/dlt/trend/', '大乐透号码走势'],
    ['/qlc/trend/', '七乐彩号码走势'],
    ['/fc3d/trend/', '福彩3D走势'],
    ['/pl3/trend/', '排列三走势'],
  ];

  ///
  /// 不记录的路由
  ///
  static const List<String> ignored = [
    '/',
    '/main',
    '/login',
    '/splash',
    '/browse',
  ];

  static BrowseHistoryStore? _instance;

  factory BrowseHistoryStore() {
    _instance ??= Get.put<BrowseHistoryStore>(BrowseHistoryStore._initialize());
    return _instance!;
  }

  BrowseHistoryStore._initialize();

  ///
  /// 全部记录,按时间倒序
  ///
  List<BrowseEntry> entries = [];

  ///
  /// 是否已加载
  ///
  bool _loaded = false;

  ///
  /// 从本机读取
  ///
  void initialize() {
    if (_loaded) {
      return;
    }
    List<Map>? cached = Storage().getObjectList(cacheKey);
    if (cached != null) {
      entries =
          cached.map((e) => BrowseEntry.fromJson(Map<String, dynamic>.from(e))).toList()
            ..sort((a, b) => b.time.compareTo(a.time));
    }
    _loaded = true;
    update();
  }

  ///
  /// 记录一次浏览
  ///
  /// [path] 为实际路由(动态参数已填充)
  ///
  void record(String path) {
    initialize();
    if (ignored.contains(path)) {
      return;
    }
    String title = titleOf(path);
    if (title.isEmpty) {
      return;
    }
    ///
    /// 同一页面只保留最近一次
    ///
    entries.removeWhere((e) => e.path == path);
    entries.insert(
      0,
      BrowseEntry(path: path, title: title, time: DateTime.now()),
    );
    if (entries.length > maxEntries) {
      entries = entries.sublist(0, maxEntries);
    }
    _persist();
    update();
  }

  ///
  /// 清空浏览历史
  ///
  void clear() {
    entries = [];
    _persist();
    update();
  }

  ///
  /// 删除一条记录
  ///
  void remove(String path) {
    entries.removeWhere((e) => e.path == path);
    _persist();
    update();
  }

  ///
  /// 根据路由推断标题
  ///
  String titleOf(String path) {
    if (routeTitles.containsKey(path)) {
      return routeTitles[path]!;
    }
    for (List<String> pattern in routePatterns) {
      if (path.startsWith(pattern[0])) {
        return pattern[1];
      }
    }
    return '';
  }

  ///
  /// 持久化
  ///
  void _persist() {
    Storage().putObjectList(cacheKey, entries.map((e) => e.toJson()).toList());
  }
}

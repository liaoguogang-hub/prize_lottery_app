import 'package:get/get.dart';
import 'package:prize_lottery_app/app/app_repository.dart';
import 'package:prize_lottery_app/app/model/app_resource.dart';
import 'package:prize_lottery_app/env/env_profile.dart';
import 'package:prize_lottery_app/utils/storage.dart';

class ResourceStore extends GetxController {
  ///
  static const String appResourceKey = 'app_resources';

  ///
  /// 本地兜底资源目录
  ///
  static const String localIconDir = 'assets/images/icons/';

  ///
  /// 已随包打包、且上游原本只从 CDN 下发的图标
  ///
  /// 服务端不可用时改用这些本地图标,避免界面出现空白圆圈
  ///
  static const Map<String, String> localIcons = {
    'zonghe_analyze_icon': 'assets/images/icons/zonghe_analyze_icon.png',
    'trend_analyze_icon': 'assets/images/icons/trend_analyze_icon.png',
    'filter_analyze_icon': 'assets/images/icons/filter_analyze_icon.png',
    'calc_analyze_icon': 'assets/images/icons/calc_analyze_icon.png',
    'history_analyze_icon': 'assets/images/icons/history_analyze_icon.png',
    'master_analyze_icon': 'assets/images/icons/master_analyze_icon.png',
    'chart_analyze_icon': 'assets/images/icons/chart_analyze_icon.png',
    'hot_analyze_icon': 'assets/images/icons/hot_analyze_icon.png',
    'pk_analyze_icon': 'assets/images/icons/pk_analyze_icon.png',
    'alert_analyze_icon': 'assets/images/icons/alert_analyze_icon.png',
    'early_warning_icon': 'assets/images/icons/alert_analyze_icon.png',
    'fast_analyze_icon': 'assets/images/icons/calc_analyze_icon.png',
    'full_analyze_icon': 'assets/images/icons/chart_analyze_icon.png',
    'lotto_intellect_icon': 'assets/images/icons/master_analyze_icon.png',
  };

  static ResourceStore? _instance;

  factory ResourceStore() {
    _instance ??=
        Get.put<ResourceStore>(ResourceStore._initialize());
    return _instance!;
  }

  ResourceStore._initialize();

  ///
  /// 资源文件集合
  ///
  Map<String, AppResource>? _resources;

  ///
  /// 取资源地址
  ///
  /// 优先使用服务端下发的 CDN 地址;服务端不可用时回退到随包打包的本地图标
  ///
  String resource(String key) {
    String remote = resources?[key]?.uri ?? '';
    if (remote.isNotEmpty) {
      return remote;
    }
    return localIcons[key] ?? '';
  }

  Future<void> loadResource() async {
    try {
      await AppInfoRepository.getAppResources(Profile.props.appNo)
          .then((value) => resources = value);
    } catch (_) {
      ///
      /// 服务端不可用,使用本地图标兜底
      ///
    }
  }

  ///
  /// 获取资源集合
  ///
  Map<String, AppResource>? get resources {
    ///本地内存的资源
    if (_resources != null) {
      return _resources;
    }

    ///本地缓存的资源
    Map? json = Storage().getObject(appResourceKey);
    if (json != null && json.isNotEmpty) {
      _resources =
          json.map((key, value) => MapEntry(key, AppResource.fromJson(value)));
      update();
      return _resources;
    }
    return null;
  }

  ///
  /// 设置资源集合
  ///
  set resources(Map<String, AppResource>? resources) {
    if (resources == null || resources.isEmpty) {
      return;
    }
    Storage().putObject(appResourceKey, resources);
    _resources = resources;
    update();
  }
}

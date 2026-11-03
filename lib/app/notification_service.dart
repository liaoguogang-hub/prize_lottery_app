import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

///
/// 本地通知服务
///
/// 用于开奖后核奖结果的本地通知提醒
///
class NotificationService {
  ///
  /// 核奖提醒通知渠道 id
  ///
  static const String prizeChannelId = 'ssq_prize_check';

  ///
  /// 核奖提醒通知渠道名称
  ///
  static const String prizeChannelName = '开奖核奖提醒';

  ///
  /// 通知插件实例
  ///
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  ///
  /// 是否已初始化
  ///
  static bool _initialized = false;

  ///
  /// 初始化通知插件
  ///
  static Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const InitializationSettings settings =
        InitializationSettings(android: android, iOS: darwin);
    try {
      bool? result = await _plugin.initialize(settings);
      _initialized = true;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  ///
  /// 申请通知权限
  ///
  /// 返回是否已获得权限
  ///
  static Future<bool> requestPermission() async {
    try {
      await initialize();
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidFlutterLocalNotificationsPlugin? android = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        bool? granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        IOSFlutterLocalNotificationsPlugin? ios = _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        bool? granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  ///
  /// 查询是否已获得通知权限
  ///
  static Future<bool> hasPermission() async {
    try {
      await initialize();
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidFlutterLocalNotificationsPlugin? android = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        bool? granted = await android?.areNotificationsEnabled();
        return granted ?? false;
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  ///
  /// 弹出核奖结果通知
  ///
  /// [id] 通知 id,相同 id 会覆盖旧通知
  ///
  static Future<void> showPrizeResult({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        prizeChannelId,
        prizeChannelName,
        channelDescription: '双色球开奖后自动核奖结果提醒',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      );
      const DarwinNotificationDetails darwin = DarwinNotificationDetails();
      const NotificationDetails details =
          NotificationDetails(android: android, iOS: darwin);
      await _plugin.show(id, title, body, details);
    } catch (e) {
      ///
      /// 通知失败不影响主流程
      ///
    }
  }
}

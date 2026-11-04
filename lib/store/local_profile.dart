import 'dart:math';

import 'package:get/get.dart';
import 'package:prize_lottery_app/utils/storage.dart';

///
/// 本地用户档案
///
/// 原工程的账号体系依赖服务端短信验证码,而服务端已不可用。
/// 本档案在完全离线的条件下提供账号等价能力:昵称、积分、签到、会员状态。
///
class LocalProfile extends GetxController {
  ///
  /// 档案存储键
  ///
  static const String profileKey = 'local_profile_v1';

  ///
  /// 签到积分
  ///
  static const int signPoints = 5;

  static LocalProfile? _instance;

  factory LocalProfile() {
    _instance ??= Get.put<LocalProfile>(LocalProfile._initialize());
    return _instance!;
  }

  LocalProfile._initialize();

  ///
  /// 是否已创建本地档案
  ///
  bool _ready = false;

  bool get ready => _ready;

  ///
  /// 本地用户标识
  ///
  String _uid = '';

  String get uid => _uid;

  ///
  /// 昵称
  ///
  String _nickname = '';

  String get nickname => _nickname;

  ///
  /// 积分
  ///
  int _points = 0;

  int get points => _points;

  ///
  /// 已签到的日期(YYYY-MM-DD)
  ///
  List<String> _signDays = [];

  List<String> get signDays => _signDays;

  ///
  /// 会员到期时间戳,0 表示非会员
  ///
  int _memberExpireAt = 0;

  int get memberExpireAt => _memberExpireAt;

  ///
  /// 是否为会员
  ///
  bool get isMember =>
      _memberExpireAt > DateTime.now().millisecondsSinceEpoch;

  ///
  /// 读取或创建本地档案
  ///
  void initialize() {
    Map? saved = Storage().getObject(profileKey);
    if (saved == null) {
      _uid = _generateUid();
      _nickname = '游客${_uid.substring(_uid.length - 4)}';
      _points = 0;
      _signDays = [];
      _memberExpireAt = 0;
      _ready = true;
      _persist();
      return;
    }
    _uid = '${saved['uid'] ?? ''}';
    _nickname = '${saved['nickname'] ?? ''}';
    _points = int.tryParse('${saved['points'] ?? 0}') ?? 0;
    _memberExpireAt = int.tryParse('${saved['memberExpireAt'] ?? 0}') ?? 0;
    List days = saved['signDays'] as List? ?? [];
    _signDays = days.map((e) => '$e').toList();
    _ready = _uid.isNotEmpty;
    update();
  }

  ///
  /// 是否今天已签到
  ///
  bool get signedToday => _signDays.contains(_today);

  ///
  /// 签到,返回获得的积分,已签到返回 0
  ///
  int signIn() {
    if (signedToday) {
      return 0;
    }
    _signDays.add(_today);
    _points += signPoints;
    _persist();
    update();
    return signPoints;
  }

  ///
  /// 增加积分
  ///
  void addPoints(int value) {
    _points += value;
    if (_points < 0) {
      _points = 0;
    }
    _persist();
    update();
  }

  ///
  /// 修改昵称
  ///
  void setNickname(String value) {
    String name = value.trim();
    if (name.isEmpty) {
      return;
    }
    _nickname = name;
    _persist();
    update();
  }

  ///
  /// 开通本地会员(到期时间由外部传入)
  ///
  void setMember(int expireAt) {
    _memberExpireAt = expireAt;
    _persist();
    update();
  }

  ///
  /// 生成档案标识
  ///
  String _generateUid() {
    Random random = Random.secure();
    String uid = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    for (int i = 0; i < 8; i++) {
      uid += random.nextInt(36).toRadixString(36);
    }
    return uid;
  }

  ///
  /// 今天的日期字符串
  ///
  String get _today {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  ///
  /// 持久化
  ///
  void _persist() {
    Storage().putObject(profileKey, {
      'uid': _uid,
      'nickname': _nickname,
      'points': _points,
      'signDays': _signDays,
      'memberExpireAt': _memberExpireAt,
    });
  }
}

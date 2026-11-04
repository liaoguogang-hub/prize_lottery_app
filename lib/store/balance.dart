import 'package:get/get.dart';
import 'package:prize_lottery_app/store/local_profile.dart';
import 'package:prize_lottery_app/utils/app_features.dart';
import 'package:prize_lottery_app/views/user/model/user_balance.dart';
import 'package:prize_lottery_app/views/user/repository/user_repository.dart';

class BalanceInstance extends GetxController {
  ///
  ///
  static BalanceInstance? _instance;

  factory BalanceInstance() {
    BalanceInstance._instance ??=
        Get.put<BalanceInstance>(BalanceInstance._initialize());
    return BalanceInstance._instance!;
  }

  BalanceInstance._initialize();

  ///
  /// 余额账户
  UserBalance? _balance;

  ///
  /// 获取余额账户
  UserBalance? get balance => _balance;

  ///
  /// [surplus]-兑换获得的奖励金
  /// [coupon]-兑换消耗的积分(负数)
  void exchangeCoupon({required int surplus, required int coupon}) {
    if (_balance != null) {
      _balance!.surplus = _balance!.surplus + surplus;
      _balance!.coupon = _balance!.coupon + coupon;
      update();
    }
  }

  set incrCoupon(int coupon) {
    if (_balance != null) {
      _balance!.coupon = _balance!.coupon + coupon;
      update();
    }
  }

  set balance(UserBalance? balance) {
    _balance = balance;
    update();
  }

  ///
  /// 刷新余额账户
  ///
  /// 离线模式下账户数据全部取自本地档案:积分来自签到累计,金额类字段固定为 0
  ///
  Future<void> refreshBalance() async {
    if (!AppFeatures.serverFeaturesEnabled) {
      balance = UserBalance.fromJson({
        'balance': 0,
        'surplus': 0,
        'invite': 0,
        'coupon': LocalProfile().points,
        'voucher': 0,
        'withdraw': 0,
        'canWithdraw': 0,
        'withRmb': 0,
        'withLatest': '',
      });
      return;
    }
    try {
      balance = await UserInfoRepository.userBalance();
    } catch (_) {}
  }

  Future<void> refreshIfNull() async {
    if (balance == null) {
      refreshBalance();
    }
  }

  ///
  /// 提现
  void withdrawRmb() {}
}

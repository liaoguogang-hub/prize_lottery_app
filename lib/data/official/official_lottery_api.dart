import 'package:dio/dio.dart';
import 'package:prize_lottery_app/views/lottery/model/lottery_info.dart';

///
/// 官方开奖数据源
///
/// 上游工程的彩种列表与开奖数据全部来自自建服务端,该服务端已下线。
/// 这里改为直连官方公开接口,把结果映射成上游的 [LotteryInfo] 模型,
/// 从而使走势图、统计、遗漏、奖级计算等本地功能继续可用。
///
/// 数据来源:
/// - 中国福利彩票: https://www.cwl.gov.cn (双色球/福彩3D/七乐彩/快乐8)
/// - 中国体育彩票: https://webapi.sporttery.cn (大乐透/排列三/排列五)
///
class OfficialLotteryApi {
  ///
  /// 福彩开奖查询接口
  ///
  static const String cwlUrl =
      'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice';

  ///
  /// 体彩历史开奖接口
  ///
  static const String sportteryUrl =
      'https://webapi.sporttery.cn/gateway/lottery/getHistoryPageListV1.qry';

  ///
  /// 上游彩种标识 -> 福彩接口 name 参数
  ///
  static const Map<String, String> _cwlNames = {
    'ssq': 'ssq',
    'fc3d': '3d',
    'qlc': 'qlc',
    'kl8': 'kl8',
  };

  ///
  /// 上游彩种标识 -> 体彩接口 gameNo 参数
  ///
  static const Map<String, String> _sportteryGames = {
    'dlt': '85',
    'pl3': '35',
    'pl5': '350133',
  };

  ///
  /// 全部支持的彩种,按上游展示顺序
  ///
  static const List<String> types = [
    'fc3d',
    'pl3',
    'ssq',
    'dlt',
    'qlc',
    'kl8',
    'pl5',
  ];

  final Dio _dio;

  OfficialLotteryApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                'Referer': 'https://www.cwl.gov.cn/ygkj/wqkjgg/',
              },
            ));

  ///
  /// 查询单个彩种的最新开奖
  ///
  Future<LotteryInfo?> latest(String type) async {
    List<LotteryInfo> list = await latestList(type, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  ///
  /// 查询单个彩种的最近若干期开奖
  ///
  Future<List<LotteryInfo>> latestList(String type, {int limit = 2}) async {
    if (_cwlNames.containsKey(type)) {
      return _fetchCwl(type, limit);
    }
    if (_sportteryGames.containsKey(type)) {
      return _fetchSporttery(type, limit);
    }
    return [];
  }

  ///
  /// 查询全部彩种的最新开奖,任一彩种失败不影响其它彩种
  ///
  Future<List<LotteryInfo>> groupLatest() async {
    List<Future<List<LotteryInfo>>> tasks = types
        .map((type) => latestList(type, limit: 1)
            .catchError((_) => <LotteryInfo>[]))
        .toList();
    List<List<LotteryInfo>> results = await Future.wait(tasks);
    List<LotteryInfo> merged = [];
    for (List<LotteryInfo> item in results) {
      merged.addAll(item);
    }
    return merged;
  }

  ///
  /// 拉取福彩彩种
  ///
  Future<List<LotteryInfo>> _fetchCwl(String type, int limit) async {
    Response response = await _dio.get(
      cwlUrl,
      queryParameters: {'name': _cwlNames[type], 'issueCount': limit},
    );
    dynamic body = response.data;
    if (body is! Map) {
      return [];
    }
    List result = body['result'] as List? ?? [];
    List<LotteryInfo> list = [];
    for (dynamic row in result) {
      if (row is! Map) {
        continue;
      }
      String red = _formatBalls('${row['red'] ?? ''}');
      String blue = _formatBalls('${row['blue'] ?? ''}');
      if (type == 'fc3d') {
        ///
        /// 福彩3D 三个开奖号放在 red 里,界面按「号码 + 试机号」两段展示
        ///
        blue = '';
      }
      list.add(LotteryInfo.fromJson({
        'type': type,
        'period': '${row['code'] ?? ''}',
        'red': red,
        'blue': blue,
        'shi': '',
        'kai': '',
        'lotDate': _formatDate('${row['date'] ?? ''}'),
        'com': '',
        'last': '',
        'lastDelta': 0,
      }));
    }
    return list;
  }

  ///
  /// 拉取体彩彩种
  ///
  Future<List<LotteryInfo>> _fetchSporttery(String type, int limit) async {
    Response response = await _dio.get(
      sportteryUrl,
      queryParameters: {
        'gameNo': _sportteryGames[type],
        'provinceId': '0',
        'pageSize': limit,
        'isVerify': '1',
        'pageNo': '1',
      },
    );
    dynamic body = response.data;
    if (body is! Map) {
      return [];
    }
    dynamic value = body['value'];
    if (value is! Map) {
      return [];
    }
    List rows = value['list'] as List? ?? [];
    List<LotteryInfo> list = [];
    for (dynamic row in rows) {
      if (row is! Map) {
        continue;
      }
      List<String> balls = '${row['lotteryDrawResult'] ?? ''}'
          .trim()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();

      ///
      /// 大乐透为 5 前区 + 2 后区,其余彩种全部算作前区
      ///
      String red;
      String blue = '';
      if (type == 'dlt' && balls.length >= 7) {
        red = balls.sublist(0, 5).join(' ');
        blue = balls.sublist(5).join(' ');
      } else {
        red = balls.join(' ');
      }

      list.add(LotteryInfo.fromJson({
        'type': type,
        'period': '${row['lotteryDrawNum'] ?? ''}',
        'red': red,
        'blue': blue,
        'shi': '',
        'kai': '',
        'lotDate':
            _formatDate('${row['lotteryDrawTime'] ?? ''}'.split(' ').first),
        'com': '',
        'last': '',
        'lastDelta': 0,
      }));
    }
    return list;
  }

  ///
  /// 把 "09,10,13" 或 "12 13 23" 统一成 "09 10 13" 形式的两位数空格串
  ///
  static String _formatBalls(String raw) {
    String text = raw.trim();
    if (text.isEmpty) {
      return '';
    }
    return text
        .split(RegExp(r'[,\s]+'))
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e)?.toString().padLeft(2, '0') ?? e)
        .join(' ');
  }

  ///
  /// 把 2026-11-03(二) 或 2026-11-03 统一成 yyyy/MM/dd
  ///
  static String _formatDate(String raw) {
    String head = raw.split('(').first.trim().replaceAll('-', '/');
    if (head.length >= 10) {
      return head.substring(0, 10);
    }
    return head;
  }
}

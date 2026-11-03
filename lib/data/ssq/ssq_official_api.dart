import 'package:dio/dio.dart';
import 'package:prize_lottery_app/data/ssq/ssq_draw.dart';

///
/// 中国福利彩票官方开奖接口客户端
///
/// 数据来源: https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice
/// 该接口公开可访问,返回体形如 {"state":0,"result":[{...}]}
///
class SsqOfficialApi {
  ///
  /// 官方开奖查询接口
  ///
  static const String baseUrl =
      'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice';

  ///
  /// 单次请求的最大期数,官方接口最多返回约 2000 期
  ///
  static const int maxIssueCount = 3000;

  late Dio _dio;

  SsqOfficialApi() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
          'Referer': 'https://www.cwl.gov.cn/ygkj/wqkjgg/',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
  }

  ///
  /// 按期号顺序倒序拉取历史开奖记录
  ///
  /// [issueCount] 为拉取期数,传 null 时使用 [maxIssueCount]
  ///
  Future<List<SsqDraw>> fetchHistory({int? issueCount}) async {
    int count = (issueCount ?? maxIssueCount).clamp(1, maxIssueCount);
    Response response = await _dio.get(
      baseUrl,
      queryParameters: {'name': 'ssq', 'issueCount': count},
    );
    return parseDraws(response.data);
  }

  ///
  /// 解析接口返回体
  ///
  List<SsqDraw> parseDraws(dynamic body) {
    if (body is! Map) {
      return [];
    }
    final result = body['result'];
    if (result is! List) {
      return [];
    }
    List<SsqDraw> draws = [];
    for (final item in result) {
      if (item is Map) {
        SsqDraw draw =
            SsqDraw.fromOfficial(Map<String, dynamic>.from(item));
        if (draw.period.isNotEmpty && draw.reds.length == 6) {
          draws.add(draw);
        }
      }
    }
    return draws;
  }
}

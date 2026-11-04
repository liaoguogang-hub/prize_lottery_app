import 'package:get/get.dart';
import 'package:prize_lottery_app/store/browse_history.dart';

class RouteObservers {
  ///
  /// 路由中间件处理
  ///
  static void observer(Routing? routing) {
    if (routing == null) {
      return;
    }
    ///
    /// 记录本地浏览历史(上游该数据由服务端存储,服务端下线后改为本机记录)
    ///
    BrowseHistoryStore().record(routing.current);
  }
}

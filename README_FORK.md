# 二次开发说明:双色球助手

本仓库 fork 自 [zjpjohn/prize_lottery_app](https://github.com/zjpjohn/prize_lottery_app)(Flutter 3.27 / GetX 的开源彩票客户端),
在原工程基础上新增了一套**完全本地化、不依赖服务端**的双色球能力,并产出可直接安装的 Android APK。

## 一、开发背景

上游工程的所有数据(开奖、历史、预测、专家、会员)都来自 `api.icaiwa.com`。实测该域名已无法访问:

```
$ curl -o /dev/null -w "%{http_code}" https://api.icaiwa.com
000
```

因此原工程在当前环境下大量页面会请求失败(首页与彩种页停在「连接超时」),预测功能完全不可用。
本次二次开发把双色球相关的核心能力改为**官方接口 + 本地计算**,使 APK 独立可用。

## 二、功能对照

| 需求 | 实现位置 | 说明 |
| --- | --- | --- |
| 1. APK | `android/` | `flutter build apk` 直接产出;无正式密钥时回退为 debug 签名 |
| 2. 自动生成随机数 | `lib/data/ssq/ssq_random_picker.dart` | 单式 / 复式 / 胆拖,Fisher-Yates 无放回抽取,`Random.secure()` 熵源 |
| 3. 预测系统 | `lib/data/ssq/ssq_predictor.dart` | 6 种策略(热号/冷号/遗漏/均衡/均值回归/综合集成),按策略权重加权抽样,多注结果互不相同;内置滚动回测与随机基准对比 |
| 4. 搭载历史数据 | `lib/data/ssq/ssq_history_store.dart`、`assets/data/ssq_history.json` | 内置 2084 期官方历史数据,并可联网增量更新 |
| 5. 自动核奖与通知 | `lib/app/prize_watcher.dart`、`lib/store/my_ticket.dart` | 已购彩票本地存档,WorkManager 周期任务拉取开奖,自动比对并弹本地通知 |
| 6. Fork 后二次开发 | 本仓库 | 见第八节改动清单 |

## 三、数据来源

全部使用**中国福利彩票官方公开接口**,不抓取第三方站点:

```
https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice?name=ssq&issueCount=N
```

- 单次最多返回约 2084 期(2013001 至今),含每期红蓝球、奖级中奖注数与单注奖金、销售额、奖池余额
- `assets/data/ssq_history.json` 为首次安装预置的历史数据(约 919 KB),保证离线也能用
- 运行时增量刷新并与本地缓存合并,按期号去重

## 四、奖级规则与核奖实现

| 奖级 | 条件 | 奖金 |
| --- | --- | --- |
| 一等奖 | 6+1 | 浮动,取当期开奖公布金额 |
| 二等奖 | 6+0 | 浮动,取当期开奖公布金额 |
| 三等奖 | 5+1 | 3000 元 |
| 四等奖 | 5+0 或 4+1 | 200 元 |
| 五等奖 | 4+0 或 3+1 | 10 元 |
| 六等奖 | 2+1 或 1+1 或 0+1 | 5 元 |

核奖(`lib/data/ssq/ssq_prize_checker.dart`)用组合数精确计算各奖级注数,不做逐注枚举:

- 单式 / 复式:命中 h 个红球的组合数 = `C(a, h) * C(n - a, 6 - h)`
- 胆拖:胆码必选,组合数 = `C(拖码命中, j) * C(拖码未命中, 6 - 胆数 - j)`

算法正确性由 `tool/verify_core.dart` 覆盖(49 项断言,含全部奖级、复式与胆拖组合数、预测多样性):

```bash
dart run tool/verify_core.dart
```

## 五、自动核奖与通知链路

```
用户点击「我已购买」
   └─> MyTicketStore.add()            写入 shared_preferences,记录期号/号码/倍数
        └─> PrizeWatcher.initialize()  注册 WorkManager 周期任务(每 2 小时)
             └─> 后台 isolate
                  ├─> 拉取官方最新开奖
                  ├─> MyTicketStore.check()  按官方规则比对
                  └─> NotificationService.showPrizeResult()  本地通知告知是否中奖
```

- 通知使用 `flutter_local_notifications` 18.x(与工程内 `device_calendar` 的 `timezone` 版本保持一致)
- 后台周期任务使用 `workmanager` 0.6.0,`ExistingWorkPolicy.keep` 保证不重复注册
- Android 13+ 需要运行时申请通知权限,「我的彩票」页提供「开启通知」按钮
- 前台也提供「立即核奖」按钮,便于在国产 ROM 限制后台任务时手动核对

## 六、新增目录

```
lib/data/ssq/                     双色球数据层(模型/官方接口/仓库/机选/预测/核奖)
lib/store/my_ticket.dart          已购彩票本地存档与核奖
lib/app/notification_service.dart  本地通知封装
lib/app/prize_watcher.dart        周期核奖调度与后台任务入口
lib/views/ssq/                    双色球助手界面(机选/预测/开奖/我的彩票)
assets/data/ssq_history.json      预置历史开奖数据
third_party/                      修补过的本地依赖(见第七节)
tool/verify_core.dart             核心算法验证脚本
```

**入口**:底部导航新增第 5 个页签「助手」(首页/开奖/专家/我的/助手),另有路由 `/ssq/assistant`。
放在底部导航而不是上游的彩种页,是因为上游彩种页在服务端不可用时会整页替换成错误态,入口会被吞掉。

## 七、依赖与构建

### 本地依赖已内置

上游工程有两个指向作者本机路径的依赖(`D:/flutter/device_calendar`),另有两个插件不兼容新版 Flutter。
本次把 4 个依赖都修好后内置到 `third_party/`,仓库可独立克隆构建:

| 依赖 | 修补内容 |
| --- | --- |
| `third_party/device_calendar` | SDK 约束 `>=2.12.0 <3.0.0` → `>=3.0.0 <4.0.0` |
| `third_party/liquid_swipe_flutter` | 无需修补,原样内置 |
| `third_party/r_upgrade` | 移除 v1 嵌入残留的 `registerWith(Registrar)`,插件本身已实现 v2 嵌入;SDK 约束同步放宽 |
| `third_party/image_gallery_saver` | 移除未使用的 `PluginRegistry.Registrar` 导入;SDK 约束同步放宽 |

各依赖的 `LICENSE` 文件均已保留。

### 工具链

- Flutter 3.44.2 / Dart 3.12.2
- JDK 17
- Android SDK:compileSdk 36、build-tools 36.x、AGP 8.11.1、Kotlin 2.2.20、Gradle 8.14.2

### 出包

```bash
flutter pub get
flutter build apk --debug        # 产物 build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release --no-tree-shake-icons
```

> `--no-tree-shake-icons` 是必须的:上游有非 const 的 `IconData` 构造,图标摇树会失败。
> release 包走 R8,缺少正式密钥时回退为 debug 签名,配置密钥见 `android/app/build.gradle` 的 `keystoreProperties`。

### 国内网络

构建时建议指定镜像,否则 Flutter 引擎产物与 Maven 依赖可能长时间无响应:

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## 八、相对上游的改动清单

| 文件 | 改动 |
| --- | --- |
| `pubspec.yaml` | 新增 `flutter_local_notifications`、`workmanager`;`assets/data/`;4 个依赖改为 `third_party/` 内置 |
| `android/settings.gradle` | AGP 8.1.0 → 8.11.1,Kotlin 1.8.22 → 2.2.20,pluginManagement 增加阿里云镜像 |
| `android/build.gradle` | compileSdk 34 → 36;Java/Kotlin 目标版本 1.8 → 17;统一各插件的 Kotlin `jvmTarget`(部分插件写死 1.8/11,会与 Java 17 冲突) |
| `android/app/build.gradle` | Java 17;开启 core library desugaring(`flutter_local_notifications` 依赖 java.time);签名配置在缺少密钥库时回退 debug 签名;移除与 AGP 8 冲突的 `com.android.support:multidex`;移除与 Flutter 3.44 的 `ndk.abiFilters` 冲突的旧式 `splits.abi` |
| `android/app/proguard-rules.pro` | 补充 Play Core 与 javax 注解的 R8 规则 |
| `android/gradle.properties` | 增加 HTTP 连接/读取超时,避免依赖下载卡死 |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.3 → 8.14.2 |
| `lib/main.dart` | 启动时初始化 `PrizeWatcher` |
| `lib/utils/storage.dart` | `initialize()` 改为幂等,避免重复调用抛 `LateInitializationError` |
| `lib/routes/names.dart`、`lib/routes/pages.dart` | 注册 `/ssq/assistant` 路由 |
| `lib/views/main/main_view.dart` | 底部导航新增「助手」页签 |

## 九、已知限制

- 上游原有的会员、充值、专家、战绩、聊天等模块依赖已下线的服务端,在当前环境下不可用,本次未做适配
- 官方接口单次最多返回 2084 期,更早的历史未纳入内置数据集
- 应用需在系统设置中允许后台活动与自启动,部分国产 ROM 会额外限制 WorkManager 周期任务,此时可回到应用内点「立即核奖」
- 预测策略的中奖率与随机基准相当(回测结果会在界面上如实展示)。双色球每期独立同分布,历史数据无法提高中奖概率
- 本工程仅用于技术学习与个人研究,**不提供购彩服务,请理性购彩**

## 十、许可与来源

上游工程未附带 LICENSE 文件,本 fork 仅用于个人学习与二次开发用途。
`third_party/` 下的依赖各自保留原项目的 LICENSE。
双色球开奖数据版权归中国福利彩票发行管理中心所有,此处仅作技术演示引用。

# 更新日志

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

版本号同步维护在两处：

- `pubspec.yaml` 的 `version` 字段(决定 APK 内显示的 `versionName`)
- Git 标签 `vX.Y.Z`

> 注:1.0.0 ~ 1.2.0 三个版本发布时 `pubspec.yaml` 的版本号尚未同步,包内 `versionName` 均为 `1.0.0`。
> 自 1.3.0 起版本号与 Git 标签严格一致,并由 `tool/release.sh` 统一维护。

## [1.3.3] - 2026-11-04

### 修复

- **浏览历史**:原页面读取服务端接口 `/ucenter/app/browse/...`,服务端下线后恒为空。
  改为本机记录:新增 `BrowseHistoryStore`,由路由回调写入(最多 200 条、同页面去重),
  列表页按期倒序展示,支持单条删除与清空
- **使用指南**:原页面用 WebView 加载 `https://cdn.icaiwa.com/app/manual/manual_book.html`,
  该域名已下线,页面永久空白。改为随包内置的说明内容,涵盖数据来源、助手用法、
  核奖规则、分析工具与免责提示

## [1.3.2] - 2026-11-04

### 变更

「我的」页改造为展示真实数据,去掉全部依赖服务端的内容:

- 顶部改为本地档案昵称(可点击修改),副标题说明数据保存在本机;移除消息入口
- 四个账户数字(奖励金 / 金币 / 积分 / 代金券,恒为 0)替换为**我的彩票真实数据**:
  全部记录 / 待开奖 / 已中奖 / 累计奖金
- 「主要频道」改为「快捷入口」,指向 我的彩票 / 号码走势 / 历史开奖 / 选号工具
- 「彩票助手」入口改指本地助手页(原指向服务端页面)
- 未登录态点击不再跳转到无法完成的注册页,改为直接创建本地档案
- 昵称改为监听本地档案,修改后即时刷新

## [1.3.1] - 2026-11-04

### 修复

- 首页功能入口图标显示为空白圆圈:上游的 `*_analyze_icon` 系列图标只由服务端 CDN 下发,
  `icaiwa.com` 整族域名下线后必然加载失败。现随包生成一套本地图标作为兜底
  (`assets/images/icons/`),`ResourceStore` 在服务端不可用时自动回退
- 首页功能入口排版错乱:原先固定 5 列 `Row` + `Expanded`,隐藏部分入口后会留下空列且末行错位,
  改为 `Wrap` 自适应流式布局
- 「专家」页签空白:该页原为服务端上的专家账号与推荐方案,无服务端则无内容。
  改为**本地选号工具聚合页**,按彩种列出完全本地可用的综合分析、号码走势、缩水过滤、
  奖金计算、历史开奖
- 补齐 Dio 新增的 `transformTimeout` 异常分支(原 `switch` 未穷尽,运行时抛错)

## [1.3.0] - 2026-11-04

### 新增

- 本地选号统计:`LocalCensusCalculator` 按官方开奖记录在本地计算选号统计,
  覆盖双色球、大乐透、七乐彩三个数字型彩种
  - 综合分析 / 比率(臻选牛人)/ 整体分析三个页面恢复
  - 统计口径与上游图例一致:三胆 / 12码 / 20码 / 25码为号码在对应窗口期的出现次数,
    杀三码 / 杀六码为对应窗口期的未出现期数
- `CHANGELOG.md` 与 `tool/release.sh`:版本号、标签、Release 的统一维护流程
- GitHub Actions:推送 `v*` 标签时自动构建 APK 并挂到 Release

### 变更

- 首页彩种页入口统一收敛:隐藏「专家PK」「号码预警」「热点分析」
  (前者的算法在服务端,后两者在上游即为未实现的占位页)

## [1.2.0] - 2026-11-04

### 新增

- `LocalOmitCalculator`:按官方开奖记录本地推算号码遗漏,结构与原接口一致
  - 数字型彩种按红球 / 蓝球逐号统计,位数型彩种按各位 0-9 统计
  - 连带恢复号码走势、通用遗漏、排列五遗漏
- `OfficialLotteryApi.rawDraw`:按期号回溯官方原始记录(含奖级、销量、奖池)
- `README_OFFLINE.md`:离线化改造的方案、实现与未完成项

### 变更

- 开奖详情页接入官方数据,恢复奖级明细
- 详情页离线时跳过专家推荐,避免整页卡在加载态

## [1.1.0] - 2026-11-04

### 新增

- `LocalProfile`:本地用户档案(uid / 昵称 / 积分 / 签到 / 会员),完全存于本机,
  替代已下线的短信验证码账号体系
- `OfficialLotteryApi`:直连中国福彩与中国体彩官方接口,覆盖 7 个彩种
- `AppFeatures`:全工程统一的功能开关

### 变更

- 登录页新增「无需账号,直接使用」入口;路由守卫在有本地档案时放行
- 后端不可达时不再强制跳转登录页
- 签到、积分、余额、会员改为本地实现
- 开奖数据、历史开奖、首页彩种页改走官方接口
- 隐藏必然失败的入口(关注收藏 / 选号攻略 / 邀请赚钱 / 我的订单 / 账户安全 / 反馈建议 等)

## [1.0.0] - 2026-11-03

### 新增

- 双色球助手模块,完全本地化不依赖服务端
  - 机选:单式 / 复式 / 胆拖,Fisher-Yates 无放回抽取,`Random.secure()` 熵源
  - 预测:6 种策略加权抽样,附滚动回测与随机基准对比
  - 历史数据:内置 2084 期官方开奖数据,并可联网增量更新
  - 自动核奖:已购彩票本地存档,按官方奖级规则组合数精确判定,支持复式与胆拖
  - 定期通知:WorkManager 周期任务拉取开奖并自动比对,本地通知告知是否中奖
- 构建链升级至 Flutter 3.44.2 / AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14.2 / compileSdk 36 / Java 17
- `tool/verify_core.dart`:核心算法验证脚本(49 项断言)
- `third_party/`:修补后的本地依赖内置,仓库可独立克隆构建

[1.3.3]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.3.3
[1.3.2]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.3.2
[1.3.1]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.3.1
[1.3.0]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.3.0
[1.2.0]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.2.0
[1.1.0]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.1.0
[1.0.0]: https://github.com/liaoguogang-hub/prize_lottery_app/releases/tag/v1.0.0

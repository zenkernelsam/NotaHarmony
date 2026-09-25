# 原版 LIBRARY_HOME 旗标判定更正 + 远程配置默认值全量扫描（JADX, decompiled_1.0.3）

日期：2026-09-25。来源：`decompiled_1.0.3` JADX 输出 + `resources/`。

## 结论

与 ADR-0690（ZOOM_VIEW）同一模式：ADR-0655 将 `LIBRARY_HOME`
登记为“旗标关闭态=Harmony 现状”，经复核其远程配置打包默认 =
`true` —— 1.0.3 原版资料库导航**默认含 Home 分区**，Harmony 缺该
分区属延迟移植缺口而非旗标对等。对 `core_remoteconfig__remote_config_
defaults.xml` 全部 51 键与 `ac4` 旗标注册表交叉扫描后，远程键默认
`true` 且被登记为“旗标关闭”的仅剩本项；其余 `true` 默认旗标或为已移植
功能，或为服务端/系统依赖的 fail-closed 边界（判定不变但理由应注明
“旗标开、能力缺”而非“旗标关”）。

## LIBRARY_HOME 求值链

1. `ac4.java:182`：`ac4Var48 = new ac4("LIBRARY_HOME", 47, zb4Var,
   tsb.c, null)`，`F0 = ac4Var48`；`zb4Var`=`zb4.L`（PRODUCTION 级）。
2. `tsb.java`：`extends lrb`，键 `"androidLibraryHome"`。
3. `lc4.a` PRODUCTION(ordinal 3) 分支 → `trb.e(tsb.c)` →
   `sh4.a()`（同 ADR-0690 详述的链：`w51.a()`=JUnit 探测生产恒
   false、`b()`=PRODUCTION>INTERNAL 恒 false → 必走远程分支）。
4. `core_remoteconfig__remote_config_defaults.xml`：
   `androidLibraryHome = true`（打包默认）。

## 旗标开启的表面（原版）

- `ajh.java:335`：`lc4.a(ac4.F0)` 为真 → 资料库导航列表插入
  `feature_library__home` 分区项。
- `va7.java:30`、`wa7.java:118`：`lc4.a(ac4.F0)` 门控分区图标
  （选中态 `tnc.a`/`snc`）。
- Home 内容族（`ksh`）："Let's get started" 双 CTA 卡
  （`home_record_lecture` / `home_take_notes` + starter 变体）、
  `home_favorite_notes` 区、`home_recent_notes` 区、
  `home_study_up_next`（Learn 面，`ac4` Learn 族旗标另行门控，
  ADR-0652 fail-closed 维持）；`oi5/pi5/hs4/haj/aj5` 卡片网格。

## 51 键远程默认值扫描分类

### 默认 true —— 已移植/等价覆盖

| 远程键 | ac4 旗标 | 状态 |
|---|---|---|
| androidPencil | PENCIL(1) | 已移植 |
| androidSnapToGrid | SNAP_TO_GRID(7) | 已移植（snap 网格候选） |
| androidDeselectMode | DESELECT_MODE(9) | 已移植（auto_deselect_eraser） |
| androidStrokeStyle | NOTE_TOOLBOX_STROKE_STYLE(11) | 已移植（画笔样式） |
| androidPartialEraser | PARTIAL_ERASER(14) | 已移植 |
| androidDocumentScanning | LIBRARY_DOC_SCAN(15) | 已移植 |
| androidNoteTapeTool | NOTE_TAPE_TOOL(35) | 已移植（胶带） |

### 默认 true —— 服务端/系统/供应商依赖 fail-closed（登记不变）

| 远程键 | ac4 旗标 | 依赖 |
|---|---|---|
| androidViewOnly | VIEW_ONLY(16) | 协作后端（ADR-0644） |
| androidMultiplayerPresence | MULTIPLAYER_PRESENCE(17) | 协作后端（ADR-0644） |
| androidVersionHistory | VERSION_HISTORY(18) | 私有版本历史后端（ADR-0670） |
| androidSpenQuickTools | SPEN_QUICK_TOOLS(8) | 三星 SPen SDK（ADR-0671） |
| androidCollabRtlText | COLLAB_RTL_TEXT(12) | 协作 CRDT（ADR-0513/0658） |
| androidShowTranscripts | SHOW_TRANSCRIPTS(36) | 转写服务（ADR-0652 族） |
| androidLearnSummary / SmartNotes / LearnQuizzes / LearnChat / AiRegionAllowed | LEARN_SUMMARY(39)/SMART_NOTES(41)/LEARN_QUIZZES(42)/LEARN_CHAT(45)/AI_REGION_ALLOWED(46) | Learn AI 后端（ADR-0652） |
| androidSixMonthsPlusOnboarding | SIX_MONTHS_PLUS_ONBOARDING(24) | 订阅时长门控（ADR-0658 B） |
| androidLaunchPaywallPromo | LAUNCH_PAYWALL_PROMO(30) | 付费墙域（ADR-0662） |
| androidSingularAttribution | SINGULAR_ATTRIBUTION(48) | Singular 归因 SDK（分析边界） |
| androidOpenTelemetry | （遥测通道，非 ac4 字段） | OpenTelemetry 后端 |
| androidAudioInkSync | （h3.java tap 路径消费） | 录音-墨水同步，ADR-0068/0069 已登记为独立契约待实施 |

### 默认 true —— 判定更正（本阶段 + Phase 742）

| 远程键 | ac4 旗标 | 更正 |
|---|---|---|
| androidZoomView | ZOOM_VIEW(19) | ADR-0690：默认开 → 延迟移植缺口 |
| androidLibraryHome | LIBRARY_HOME(47) | 本阶段 ADR-0691：默认开 → 延迟移植缺口 |

### 默认 true —— 已移植/等价覆盖（续）

| 远程键 | ac4 旗标 | 状态 |
|---|---|---|
| androidEntityGroups | ENTITY_GROUPS(10) | `ac4.V` 消费方 `uw2`/`vo2`/`xtc`
  走 `fu1.c` 组扩展；Harmony `OriginalGroupSelection.ets`/
  `OriginalGroupLayering.ets` 已移植同语义 |
| androidShapeEditSnapping | SHAPE_EDIT_SNAPPING(13) | `ac4.Y` 注入
  `avc` 形状编辑会话（831/1503/1513）；Harmony `OriginalSnapGuides.ets`
  已移植吸附导引 |

### 默认 false / 非布尔 —— 旗标关闭态登记维持不变

`androidRoomSearchEngine`、`androidPlayLaunchPromo`、
`androidSubscriptionPurchaseFlow`、`androidOneTimePurchase`、
`androidPlayHashedAccountId`、`androidManageSubscriptionSettings`、
`androidStripePayment`、`androidStripeForExistingSubscribers`、
`androidStripeTiers`(OFF)、`androidSamsungIap`、
`androidLiveTranscription`、`androidMathConversion`、
`androidHandwritingToText`、`androidToolboxSecondaryTools`、
`androidFolderEmojiPicker`、`androidAnimatedImages`、
`androidNoteLimit`、`androidRequireUnlockedDevice`、
`androidMinimumBuildNumber`(0)、`androidMinimumSdkForceUpgrade`(0)、
`androidPaywallSource`(PLAY)、`androidDaysBetweenLaunchPaywallPromos`(10)。

注：`androidFolderEmojiPicker` 打包默认 false，Phase 540 已知情
选择实现策划子集选择器（证据文档明示旗标存在），属有记录的有意
偏差；`androidToolboxSecondaryTools` false → 二级工具条隐藏，
与 ADR-0658 A 类登记一致。

## Harmony 现状

经典 Library（All/Recent/Favorites/Unfiled + 文件夹树 + FAB），
无 Home 分区导航项与首页组合——继续缺省，但理由更正为
“延迟移植缺口（含 Learn 子区 fail-closed 依赖）”。

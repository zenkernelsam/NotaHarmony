# Phase 760：原版 1.4.2 反编译登记与版本差异初筛

> 日期：2026-09-29
> 证据：`docs/migration/evidence/original-1.4.2-decompile-version-delta.md`
> ADR：`docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md`
> Replay：`d02-original-1.4.2-version-delta.mjs`（17 断言，全绿）
> 性质：证据登记 + 差异初筛；无 Harmony 源码变更；产出为 T-042 直接输入。

## 背景

交接文档（SWE2-2026-09-21）P3 段要求：1.0.3 剩余 TODO 收敛后对
用户预下载的 `Notability_1.4.2` xapk 执行与 1.0.3 同法反编译，做
版本差异初筛。本阶段前 1.0.3 静态审计面已收敛（全部探面三态落地：
已移植/已登记边界/待真机），`decompiled_1.4.2/` 仍为用户预建的空目录，
故执行本阶段。

## 执行内容

1. xapk 解包提取 base APK `com.gingerlabs.notability.apk`
   （90,782,868 B，SHA-256 `764af402…f992`）；xapk 全包指纹
   `d754ab3b…ff70`（393,138,231 B）。
2. jadx-1.5.6 反编译至 `decompiled_1.4.2/`：18,071 类处理，
   产出 24,808 个 `.java`，553 类失败（混淆常态，与 1.0.3 同理）。
3. 版本号核对：1.0.1=1001 / 1.0.3=1014 / 1.4.2=1040002。
4. 非混淆签名面 diff（defpackage 混淆名跨版本重排，不直接 diff）：
   - `com/gingerlabs` 包树：+42/−2，新增 12 个功能簇（见证据文档表三）；
   - `AndroidManifest.xml`：新增 `HwrEngineService`（远端手写识别服务）、
     `ApiGatedFirebaseInitProvider`、`READ_CALENDAR` 权限、Crashlytics NDK；
   - `strings.xml`：1503→2118 键（+722/−107），新键族覆盖 Gallery 社区
     （~200 键）、贴纸商店（~80）、模板中心改版（~45）、Learn 课程表（~30）、
     Passkey/日历连接/笔记上限付费墙/闪卡分隔符等；
   - 第三方库：新增 zstd-jni，iink SDK 升级，移除 Jackson/exo/appcompat 部分组件；
   - `resources/assets`：115→576（+465/−4）——新增 36 个内置纸张模板包
     （每包 PDF×尺寸×颜色×方向 + metadata.json + HEIC 缩略图）、
     5 个 brushpack、10 个封面 PDF；移除 MyScript conf-lite 与
     en_US lite res（端侧 lite 识别下线，配合远端 HwrEngineService）；
   - 原生库：1.0.3 全部 .so 在 1.4.2 保留（iink 23→24MB、PDFNetC
     58→59MB 等升级），仅新增 Crashlytics NDK 四件与 libzstd-jni；
   - 移除键复核：`feature_learn__chat/quiz/summary/youtube` 族整体下线
     （Learn AI 移除先例），hwr/logout/theme/toolbar 键为重构更名；
     按键族统计 1.0.3 无整族功能被移除（仅 feature_learn 17→8 收缩）。

## 差异定性

1.4.2 是服务化大版本：新增功能几乎全部依赖私有后端
（Gallery 社区发布/评论/点赞、贴纸商店分发、模板云同步、远端 HWR、
Passkey/SSO、课程表解析、笔记上限）。沿用既有 fail-closed 框架登记；
本地候选（自定义模板 CRUD、闪卡分隔符、日历连接、自制贴纸）登记为
"版本差·待审"，是否回移由后续独立 Phase 逐簇判定。

## 验收对照

- 原版硬证据：xapk/APK SHA-256、manifest、包树与字符串键全部落盘登记；
- 无 Harmony 代码变更，无需 fail-closed 代码路径；
- Replay 17 断言全绿，钉住证据树存在性、指纹与标志类；
- 两份修复总纲与总进展已更新；T-042 仍为 Goal 最后一项，本阶段仅为其输入。

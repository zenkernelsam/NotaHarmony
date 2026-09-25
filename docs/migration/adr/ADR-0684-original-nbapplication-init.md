# ADR-0684: 原版 NbApplication 初始化链审计（生命周期总线 / WorkManager 工位 / 诊断件）

- 状态：已接受（收口登记）
- 日期：2026-09-25
- 阶段：Phase 736
- 证据：`docs/migration/evidence/original-nbapplication-init-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-nbapplication-init.mjs`

## 背景

继 MainActivity（ADR-0679 属性 / ADR-0681 方法）之后，本 ADR 关闭
Application 级启动面：`NbApplication.onCreate` 全部初始化项逐项
对源分类。

## 分类结论

1. **进程生命周期总线（`wya` = ProcessLifecycleOwner）**：原版以
   Activity 计数器驱动前后台事件，`hm`/`hv2`/`kc4`/`g54`/`uv7`/
   `bga`/`ecb`/`df9` 等约 8 个 DI 管理器经 `wya.N` 订阅。全部
   消费者均为同步/上传/订阅刷新/分析等**后端侧反应式管线** —
   对应用户可见面（云同步、转写上传、计费）已在既有 ADR
   fail-closed。Harmony `NoteAbility.onForeground/onBackground`
   钩子已存在（仅 hilog），因无可移植消费者而不挂分发。
   **结构性差异登记：原版有进程级前后台事件总线，Harmony 侧
   仅保留钩子占位，待任何边界解除时再接线。**
2. **WorkManager 工位**：`v98`/`mx7` WorkerFactory 表 +
   `rp8` 执行器池。`ExportSweepWorker` 语义已由
   `NoteExportTemporaryArtifactCleanup` 承担（Phase 735 补全覆盖
   面）；`NoteAssetDownloadWorker` 为云端资产同步，后端边界。
   WorkManager 本身无 Harmony 对应调度 API → 平台边界。
3. **诊断件**：`StrictMode.LAX`（显式放宽，无语义）、
   `ProcessFreezeDetector` 守护线程（内部冻结看门狗）、
   `qp8.c(cj(pid))` "App Launch" 分析事件 —— 开发诊断/遥测
   边界，不移植。
4. **内部管线**：`zb8`/`tl`/`j3e`/`y79`/`l3e`/`ch4.b`/`vv7.e`/
   `trb.f`/`lc4.f`/`fcb.a` 等静态装配与服务定位 —— DI 图内部
   接线，行为依附于上述分类的消费者，无独立可移植语义。

## 决策

- 无新增代码：所有初始化项归属上述四类。
- Harmony 应用级启动序列保持现状（ThemeStore → 持久化主题 →
  loadMainContent），与原版「DI 装配 + 生命周期订阅 + 工位
  注册」的差异属结构层，已在各消费者 ADR 中逐项登记。

## 边界与限制

- 混淆管理器职责定位到「生命周期/事件流订阅者」粒度；未发现
  未被既有 ADR 覆盖的独立用户可话语义。
- 未做模拟器/真机/Hypium 验证。

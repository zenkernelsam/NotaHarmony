# ADR-1323 — 1.0.3↔1.4.2 版本差异：新增特性移植决策

- 状态：已接受
- 日期：2026-08（Phase 1387）
- 证据：`docs/migration/evidence/phase-1387-1-4-2-version-diff.md`

## 决策

对 1.4.2（AI Note Workspace）相对 1.0.3 的全部差异，按是否依赖后端/专有 SDK 分两路处理：

1. **本地可移植项（A 类）进入后续 Phase 逐个实现**：Shape 工具、Calligraphy
   笔刷样式、线型扩展、贴纸画布放置、本地模板、CSV/RTF 导入、纸样/封面扩展。
   它们是纯画布/渲染/数据语义，符合「接近原版功能与原生体验」的 Goal。
2. **后端依赖项（B 类）走既有 fail-closed 约定**：Learn AI 学习套件、社区
   图库（collections/comments/followers）、音频转写、passkey 登录、MyScript HWR
   引擎服务、付费墙/订阅、settings/templates 云同步、WorkManager 后台、日历。
   不为之伪造后端；各自以 ADR 记录 fail-closed 边界，UI 入口按原版语义降级。

## 理由

- `com.gingerlabs.notability` 未混淆包 + Manifest + 资源 diff 是有效信号源
  （`defpackage` 混淆层逐名 diff 无意义）。
- 1.4.2 是 +17% 源 / +722 字符串的大版本跃进；不做逐项甄别会在「对齐原版」
  与「不可移植后端」间混淆边界。先把移植/不可移植分界定死，后续 Phase 才有依据。
- 项目已有 fail-closed 先例（RULER/POINTER、MyScript、SDK 私有控件）；本决策
  把同一标准推广到整个 1.4.2 增量面。

## 影响

- A 类项将成为 Phase 1388+ 的实现对象；B 类项各写 fail-closed ADR。
- 全量 Replay 不变绿不回退（Phase 1387 fixture 已纳入基线）。
- `T-042` 版本追踪仍为 Goal 末项，本 diff 是其输入之一。

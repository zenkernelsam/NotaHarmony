# Phase 826 — activity 属性级明细闭合

## 范围

三版 manifest `<activity>` 逐属性提取 + Harmony Ability/卡片配置页映射。

## 原版证据

6 个应用级 activity 三版本零差异。MainActivity 属性集：
全量 `configChanges`（7 项）、`windowSoftInputMode=adjustNothing`、
`resizeableActivity=true`、`showWhenLocked`+`turnScreenOn`——
单 Activity Compose 宿主 + 录音/课堂锁屏可达场景。

其余：MissingNativeLibraryActivity（兜底告警）、Apple/MicrosoftSignIn
（configChanges + singleTop）、两个 widget 配置 activity。

## Harmony 映射

- configChanges → ArkUI 声明式模型天然不重建。
- adjustNothing → 编辑器自绘视口自管理 IME。
- resizeable → Harmony 多窗默认支持。
- showWhenLocked → 登记平台范式差异（录音锁屏可见性由连续任务
  系统横幅承担）。
- keepScreenOn → `NotePage.keepScreenOnApplied` 编程式等价已存在。
- widget ConfigActivity → noteformability 卡片配置页。
- sign-in → fail-closed。
- NoteAbility skills：home + viewData/sendData(PDF) + browsable
  notability.com 深链（对应 796 登记的 intent-filter 面）。

## 交付物

- 证据：`docs/migration/evidence/phase-826-activity-attrs.md`
- ADR：`docs/migration/adr/ADR-0770-activity-attrs.md`
- Replay：`docs/migration/replays/d02-activity-attrs.mjs`（7 项断言）

## 验证

- 新增 Replay：7/7 一次通过。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

manifest 语义面全面闭合。候选轴：baseline.prof 热点方法抽样、
dex 常量池扫描、或 Harmony 侧死代码反向审计收尾。

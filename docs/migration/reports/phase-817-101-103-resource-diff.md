# Phase 817 — 1.0.1→1.0.3 资源/manifest 全量差(中文报告)

## 本阶段结论

补全三版谱系最前段的资源层证据：1.0.1→1.0.3 文件级
+19/−11、9 项内容变化、strings +33/−12、manifest 结构性增量。

## 关键增量

- **Singular 归因 SDK 在 1.0.3 首次随包**(kotlin_module +
  `AD_ID`/`READ_PERMISSION_SINGULAR` 权限 + AppSet)——
  归因栈上车是本段最大功能差。
- **品牌字体补全**:GT America Mono Bold、GT Flaire Extra、
  Proxima Soft Medium、Untitled Serif medium/italic ——
  1.0.1 缺的 5 个字重在 1.0.3 补全(与 Phase 803 字体面衔接)。
- **manifest**:`FileProvider`→`ExportFileProvider` 自定义导出
  Provider;新增 FB/IG 安装探测 queries;ADID collection
  meta-data。
- **strings +33**:账户删除全生命周期(confirm/error/in_progress/
  sync_failed)+ 登出同步状态族(sync_now/syncing/synced/
  unsynced/countdown)+ 付费墙键组重组 —— Phase 797
  "账户加固"结论的完整键级形态。

## Harmony 侧

归因/广告 ID/预装权限为 GMS+归因边界,fail-closed;
FB/IG 探测属 Android 分享探测,Harmony 不依赖；
导出 Provider 定制 Harmony 已有等价文件共享通道。

## 验证

- Replay:`d02-101-103-resource-diff.mjs` 15/15;全量 690/690 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-817-101-103-resource-diff.md`
- `docs/migration/replays/d02-101-103-resource-diff.mjs`
- `docs/migration/adr/ADR-0761-101-103-resource-diff.md`
- 本报告

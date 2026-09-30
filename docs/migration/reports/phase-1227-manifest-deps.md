# Phase 1227 报告 — Manifest 依赖普查

## 完成内容

- 97 组件普查：Firebase×7（crashlytics/perf/
  remoteconfig/sessions/installations/analytics/
  datatransport）+ GMS signin/measurement +
  Play billing/assetpacks + ML Kit registrars +
  GmsDocumentScanning 委托。
- 全部 GMS-family 边界 → fail-closed/HMS 等价表。

## 产出

- evidence `phase-1227-manifest-deps.md`
- fixture `d02-manifest-deps.mjs`（10/10）
- ADR-1171

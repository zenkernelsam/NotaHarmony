# Phase 1300 报告 — 数据层+应用架构总普查（里程碑）

## 完成内容

- 收敛 `com/gingerlabs/notability/` 全树（Phase 1283–
  1299）：**应用架构分层** —— `app/`(Hilt DI+Compose
  单 Activity+Startup 链+widgets×5+升级 Receiver+原生
  回退）、`auth`/`feature/login`(OAuth：GMS+Microsoft+
  Apple×3)、`core/`（性能/日志/内存/FlatBuffers/GLMath/
  网络/Retrofit)、`data/`(billing×2+learn+library/ntb+
  note ops/assets/state+search FTS+settings+transcription+
  handwriting)、`domain/`(subscription) —— 8 Room DB+
  32-op CRDT+资产同步+`.ntb` 导出 —— 完整移动笔记
  应用架构普查。

## 产出

- evidence `phase-1300-data-layer-census.md`
- fixture `d02-data-layer-census.mjs`（10/10）
- ADR-1244

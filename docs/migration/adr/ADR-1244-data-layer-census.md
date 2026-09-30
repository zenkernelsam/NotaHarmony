# ADR-1244：数据层+应用架构总普查（里程碑）

## 状态

已接受（Phase 1300，里程碑）。

## 决策

应用架构分层（壳/领域/数据/基础设施/集成）的 Harmony
映射已通过前 ADR 建立 —— 分层语义保真。

## 理由

`com/gingerlabs/notability/` 全树收敛：
`app/`(Hilt+Compose+Startup+widgets+升级)、`core/`(analytics+
logging+memory+flatbuffers+glmath+network+retrofit)、
`data/`(billing×2+learn+library+note+search+settings+
toolbar+transcription+handwriting)、`domain/`(subscription)、
`feature/login/`(OAuth×3) —— 完整分层架构。

## 后果

Harmony 分层架构映射完成 —— 8 Room DB→RdbStore、
CRDT ops→同步层、OAuth/billing/SDK → 平台适配 —
— 架构语义保真。

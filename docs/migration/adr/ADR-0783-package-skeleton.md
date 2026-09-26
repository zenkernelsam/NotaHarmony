# ADR-0783 — `com.gingerlabs` 包骨架归档

- 状态：已接受（模块图闭合）
- 证据：`docs/migration/evidence/phase-839-package-skeleton.md`
- 回放：`docs/migration/replays/d02-package-skeleton.mjs`（12/12）

## 决定

1. 非混淆包树（1.0.1/1.0.3=73 目录零差；1.4.2=95 目录/162 类，
   +22 子包）作为**权威模块图**归档；22 个新增包全部映射至
   已登记簇（calendar/gallery/stickers/notelimit/hwr/learn/
   appsearch/templates/maintenance/loginstate/user 等）。
2. 叶子语义钉扎：NoteLimitRefusedException、samsungbilling
   5 异常族、BackgroundMaintenanceWorker=CoroutineWorker、
   flatbuffers 仅剩 ValidationException 骨架。
3. Harmony 无 noteLimit 实现确认为域层缺口（与 ADR-0781
   字符串面一致）。

## 后果

非混淆类名层（模块结构）闭合；剩余审计面集中在
`defpackage/` 混淆体的语义级解码（逐主题推进）。

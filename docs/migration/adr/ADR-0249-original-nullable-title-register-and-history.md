# ADR-0249：原版显式 null title register 与可恢复历史

## 状态

Accepted - Phase 271（2026-08-18）

## 背景

Phase 245 已把本地标题编辑接到原版 `SET_METADATA.title`，Phase 270 又把 SET_METADATA 的其他六项
register 收口。但当 `l2d.field0` 的 `z2d` wrapper 存在而其 inner string 缺席时，Harmony 仍有四个分叉：

1. title policy 把合法的 wrapper-null 当作非法；
2. `original_note_title_winner.title` 的 `NOT NULL` 约束无法保存真实 winner；
3. reducer 因 `payload.title !== null` 跳过写入，显式清空既不推进 LWW 也不更新 projection；
4. NTL1、Undo action 和恢复校验只有 concrete string，无法从空显示投影恢复 nullable register。

原版 `l2d/z2d/rz1/v69/a79/dhh/u5j/m09/cl9/ft0` 及既有 APK DEX title evidence 证明 wrapper-null 是
合法且可序列化的 register value。完整行号和哈希见
`docs/migration/evidence/original-null-title-register-jadx-2026-08-18.md`。

## 决策

### 1. 三态 wire 语义保持不变

- `field0` 缺席：不 patch title register；
- wrapper 存在且 inner string 缺席：patch 为 explicit null；
- wrapper 与 inner string 均存在：patch 为 concrete 1～256 UTF-16 code units。

`OriginalNoteTitlePolicy` 的 wire validator 接受 `string | null`；UI draft 仍保持原版 200-unit 上限和
exact-empty → `New Note` 规则。null 只由入站同步、导入状态和 Undo/Redo register target 使用，不作为空文本
编辑输入。

### 2. winner 保存真实值，现有 UI/搜索列保存有效投影

数据库升至 v66。最新 `original_note_title_winner` 与迁移重建表使用：

```sql
title TEXT CHECK (title IS NULL OR length(title) BETWEEN 1 AND 256)
```

winner 的 null 不伪装成 `New Note`，而以 `note_meta.title = ''`、标题 `folded_text = ''` 作为非 NULL
投影，以兼容既有列表、查询和搜索 schema。读取 title state 时必须同时检查 winner row presence 和
materialized projection；winner 存在但 projection 不匹配时 fail closed。

### 3. reducer 与 LWW 必须把 null 当作有效 payload

`OriginalSetMetadataOperationApplier` 对 `hasTitle` 为真时无条件执行 title winner write，包括 null；严格
`(timestamp,siteId)` LWW、stale no-op、同 identity 同值幂等与同 identity 异值冲突规则不变。materialization
统一使用 `null -> ''`，并更新标题搜索 row。所有 identity/conflict 判断仍在任何 winner、projection 或 PDF
asset 写入之前完成。

### 4. 出站与 durable history 采用兼容 NTL2

`encodeOriginalSetMetadataTitle(null)` 写出 present `z2d` wrapper、缺席 inner string；concrete title 的
wire layout 不变。

`NoteTitleMutationCodec` 新格式为 NTL2：保留 NTL1 的 magic/revision/page 顺序，在 page 后增加两位 presence
flags，再只写存在的 before/after string。decoder 同时接受 NTL1 和 NTL2，拒绝非法 flags、trailing bytes、
null→null 或 concrete 空字符串。这样已有历史可恢复，新的 null↔string Undo/Redo 不会退化成空文本。

runtime `NoteTitleAction`、`PersistentHistory` 和 editor validation 使用 `string | null`；UI 状态比较时先
应用 `materializeOriginalNoteTitle(null) = ''`，持久 operation 仍使用真实 nullable target。

## 后果

- 原版显式清空 title 不再被 defer、丢失或伪装成 `New Note`；
- stale/null/concrete title 的 LWW 和 identity conflict 具有可审计、可重放的确定性；
- `note_meta`/搜索消费者无需立即改成 nullable，但调试和同步必须读取 winner 表才能区分 null 与缺席；
- 旧 NTL1 history 不需迁移，跨会话恢复与新 NTL2 history 可以共存；
- v66 迁移需要重建一个 title winner 表，旧 concrete rows 原值复制，不猜测或回填默认标题。

## 验证契约

- 原版 null wrapper、nullable accessor、snapshot、import projection、SQL aggregation 和 Room DDL evidence；
- ArkTS fixture：null title FlatBuffer、v66 DDL、NTL2 null↔string、legacy NTL1；
- `d02-original-null-title-register.mjs`：原版静态证据、v66 migration/constraint/cascade、LWW stale/idempotent/
  conflict、empty projection、FlatBuffer wrapper 和 history model；
- `d02-original-set-metadata-registers.mjs`、local title replay 与全量 replay 均继续通过；
- clean 后 `note@ohosTest`、`note@default` 只作静态编译/打包门禁，不启动设备、模拟器、虚拟机、真机或 Hypium。

## 未决边界

- 真实旧数据库升级、NOTE_BUNDLE/多设备 round-trip 与服务端同步仍需后续样本或设备验收；
- title empty projection 的列表显示、搜索 UI 和恢复手感仍需设备/集成验证；
- T-042 APK 版本追踪按 Goal 纪律继续留到最后一项。

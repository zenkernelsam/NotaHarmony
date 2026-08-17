# 修复总结：Phase 271 原版 SET_METADATA 显式 null 标题寄存器与历史

## 1. 基线与工作区纪律

- 正式且唯一可写工程：`C:\HarmonyProject\NotaHarmony`。
- `C:\Users\Cisco He\Desktop\Notability` 仅用于读取原版 APK、`decompiled_1.0.3`、JADX 和调用图证据；本阶段没有在 Desktop 创建或维护 Harmony 源码工作树。
- 本阶段开始时正式仓 `HEAD=91ea3e6`，`origin/main=c1be5f0`；Phase 264、265、266 的提交 `977fe31`、`4718f12`、`c1be5f0` 均核验为 `c1be5f0` 的祖先。
- 保留工作区既有未跟踪资产（`.codex-tmp-*`、`.hvigor-user-*`、`Chat History/`、`note/oh-package-lock.json5`），没有清理或改写 Desktop 内容。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 2. 原版缺口与证据

原版 1.0.3 的 `l2d/z2d/rz1/v69/a79/dhh/u5j/m09/cl9/ft0/e47` 及既有 APK DEX evidence 共同证明：

1. `SET_METADATA.field0` 缺席表示不 patch；wrapper 存在但 inner string 缺席表示一个合法的显式 null register 写入；wrapper 与 inner string 都存在才是 concrete title。
2. `z2d` accessor 可以返回 null，`rz1` 在 wrapper 存在时无条件把 nullable 值写入独立 title register；不能用“只处理非空字符串”代替三态语义。
3. 快照、`NOTE_BUNDLE` 和导入链会继续携带 nullable title；原版导入投影为空字符串，不是 `New Note`。Room/聚合 SQL 也保留 winning SQL NULL。
4. Undo 从旧 title register 重新包装 `SetString`，因此恢复必须保存真实 null，而不能仅保存 UI 的空字符串投影。

完整行号、源码哈希、DEX 入口和 FlatBuffer 结构见：
`docs/migration/evidence/original-null-title-register-jadx-2026-08-18.md`。

## 3. 实现内容

### 3.1 三态 title policy 与出站 wire

- `OriginalNoteTitlePolicy.ets` 的 wire validator 接受 `string | null`；concrete 仍限定 1～256 个 UTF-16 code units。
- 新增 `materializeOriginalNoteTitle(null) = ''`。UI draft 继续使用原版 200-unit 限制，精确空文本提交仍按既有规则变成 `New Note`；null 只来自入站 register、导入状态和 Undo/Redo target。
- `OriginalSetMetadataPayloadEncoder.ets` 在 title 为 null 时写出 present title wrapper、缺席 inner string；concrete title 的既有 FlatBuffer layout 不变。

### 3.2 winner、projection 与数据库迁移

- `OriginalSetMetadataOperation.ets` 的 title winner 改为 nullable。`hasTitle` 为真时无条件执行 winner write，即使 payload 是 null；严格 `(timestamp, siteId)` greater LWW、stale no-op、同 identity 同值幂等和异值冲突保持不变。
- null winner 的 `note_meta.title` 与标题搜索投影统一为 `''`，不会伪装成 `New Note`；winner row presence 与 nullable value 可独立审计。
- `DatabaseHelper.ets` 升至 v66。`original_note_title_winner.title` 改为 `CHECK (title IS NULL OR length(title) BETWEEN 1 AND 256)`，迁移通过临时表复制旧 concrete rows、删除旧表、重命名，并保留 `ON DELETE CASCADE`。
- `OriginalNoteTitlePersistence.ets` 用一条 LEFT JOIN 同时读取 winner row presence、nullable winner、materialized projection 和 revision；projection 不一致时 fail closed，并支持 null↔string 本地事务。

### 3.3 durable history、Undo/Redo 与编辑器

- `NoteTitleMutationCodec.ets` 新增 NTL2：在 revision/page 后用 presence flags 表达 nullable before/after，只编码存在的字符串；decoder 继续兼容旧 NTL1，拒绝非法 flags、trailing bytes、空 concrete title 和 null→null。
- `NoteTitleAction`、`PersistentHistory`、`UndoRedoManager` 和 `NotePage` 全链路保留 `string | null`。UI 校验比较 `null -> ''` 的 materialized projection，实际写回仍使用真实 nullable register target。
- `NoteRepositoryImpl.updateNoteTitle()` 返回真实持久化前后值及 materialized projection；普通 `NoteMeta.title === ''` 更新映射为显式 null，避免本地回写丢失 register 语义。

## 4. 证据、fixture 与 Replay

- 新增 ADR：`docs/migration/adr/ADR-0249-original-nullable-title-register-and-history.md`。
- 新增原版 evidence：`docs/migration/evidence/original-null-title-register-jadx-2026-08-18.md`。
- 新增专项 replay：`docs/migration/replays/d02-original-null-title-register.mjs`，覆盖原版 wrapper/accessor/snapshot/import/SQL 证据、v66 migration/constraint/cascade、LWW stale/idempotent/conflict、空投影、NTL2/NTL1 和显式-null FlatBuffer。
- 更新 title/background 出站 replay 与历史 title register replay 的过时源码门；更新 `DatabaseHelper.test.ets`、`OriginalSetMetadataPayloadEncoder.test.ets`、`PersistentHistory.test.ets`、`SyncedOperationInbox.test.ets`。

## 5. 验证结果

| 门禁 | 结果 |
|---|---|
| Phase 271 专项 Replay | `D02_ORIGINAL_NULL_TITLE_REGISTER_OK TOTAL=35 FAILED=0` |
| Phase 270 相关 Replay | `D02_ORIGINAL_SET_METADATA_REGISTERS_OK TOTAL=36 FAILED=0` |
| 本地 title 出站 Replay | 通过 |
| 全量 Desktop Replay | `REPLAY_FILES=256 PASSED=256 FAILED=0` |
| `git diff --check` | 通过（仅 Windows CRLF 转换提示） |
| clean | `BUILD SUCCESSFUL in 1 s 830 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 6 s 976 ms` |
| clean 后 `note@default` | `BUILD SUCCESSFUL in 43 s 353 ms`，生成 unsigned HAP |

构建只出现项目既有 ArkTS exception/deprecation 与未配置签名 warning，没有新增编译错误。`ohosTest` 仅作为 fixture 编译/打包门禁，不冒充设备运行态 assertions。

## 6. 本阶段边界与后续开放项

本阶段闭环了显式-null title 的原版 wire、入站 LWW、v66 持久化、materialized/search projection、本地出站与 durable Undo/Redo 恢复。

以下仍不能由静态 Replay/HAP 宣称完成：

- 真实旧数据库升级、多设备/服务端同步、`NOTE_BUNDLE` round-trip 与保存重启样本；
- 空投影在列表、搜索 UI 和跨页面恢复中的真实体验；
- SET_METADATA 的 PAGELESS、align-to-lines、handwriting provider、default-font inheritance、wrap consumer；
- 设备像素、性能以及 Harmony API 与原版输入/渲染差异；
- `T-042` APK 版本追踪。按 Goal 纪律，必须留到整个 Goal 最后一项，届时另写 Report 并补齐 Wiki、技术/API 文档和新手入门。

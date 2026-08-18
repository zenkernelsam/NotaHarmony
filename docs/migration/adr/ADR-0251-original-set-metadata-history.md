# ADR-0251：原版 SET_METADATA 六项持久历史与可逆性门禁

## 状态

Accepted - Phase 273（2026-08-18）

## 背景

Phase 270 已把 `SET_METADATA` field 2～7 保存为六个独立 LWW winner；Phase 272 又补齐显式 presence patch、
原版 FlatBuffer 本地 writer、生产 reducer readback 与 uploadable operation-log 原子写入。尚缺的是六项动作如何进入
全笔记持久 Undo/Redo。

原版 `vnf` 表明，撤销 `SET_METADATA` 时会按原 action touched fields 读取 NoteImpl 当前 register，再经
`u5j.H → xj2.d` 生成一条新的逆向 `SET_METADATA`。但普通五项的 null 参数在 `xj2` 中表示 omitted，只有
handwriting wrapper 能表达 explicit null；同时原版寄存器初值允许缺席。若 Harmony 把缺席 winner 猜成默认值，
历史会静默改变数据语义。

## 决策

### 1. 原版行与 Harmony companion 分工

实际 metadata mutation 始终写 uploadable `OpType.ORIGINAL_SET_METADATA`。新增本地-only
`OpType.UPDATE_NOTE_METADATA = 35` 与 `NMD1` companion，只保存：

- `fromRevision/toRevision`，且必须恰好前进一步；
- selected page identity；
- 六位 non-empty touched-field mask；
- before/after 六字段 state。

`UndoableActionType.NOTE_METADATA = 23` 只负责 runtime/history materialization，不替代原版 wire operation。

### 2. 历史 state 必须真实可逆

普通五项 touched value 不允许 null；handwriting touched null 表示 winner-present/value-null。未 touched 字段在
state 中必须为 null，不能夹带第二份隐式 patch。

如果请求 history，而任一 touched before winner 缺席，则 mutation 在分配 operation identity 前失败。无 history
的首次普通 winner 写入仍允许成功，因为它不承诺构造无法表达的逆操作。

每个 before/after state 还必须通过生产 `encodeOriginalSetMetadataFields()` 的 UTF-8 round-trip、byte budget 和
值域。这样超长 handwriting 等“能读入但不能由本地 writer 恢复”的值不会形成假历史。

### 3. Undo/Redo 生成新 original operation

Undo 以 action.after 为 expected source、action.before 为 target；Redo 方向相反。两者都调用
`updateOriginalNoteMetadata()`，重新分配 operation identity 并写更晚的 original `SET_METADATA`，不复用旧
operation bytes、timestamp 或 site identity。

为了避免异步同步/其他编辑已改变同一 register 后被旧历史覆盖，Undo/Redo 必须逐 touched field 比较 expected
source。值不匹配时不改 winner、revision 或 operation log；未 touched register 不参与门禁。

### 4. 一个事务覆盖 winner、upload 行和 companion

`NoteRepositoryImpl` 在共享 metadata mutex 下独占 SQLite transaction。生产顺序固定为：

```text
validate history/page/source/reversibility
→ allocate original identity
→ apply original reducer/readback/revision/updated_at
→ append uploadable ORIGINAL_SET_METADATA
→ allocate and append local NMD1 companion
→ commit
```

任一步失败全部 rollback。companion append 失败不能留下已生效 winner 或孤立 upload row；companion 自身不推进
structure revision。

### 5. 接入全笔记持久历史，但不发明 consumer

`PersistentHistory` 只接受单一 NMD1 companion，并恢复 `NoteMetadataAction`；`NoteCanvasView` 把它路由为 page
action，`NotePage` 负责 source-checked Undo/Redo。当前没有证据支持的 PAGELESS、align、字体继承、handwriting
provider 或 block-wrap 设置 consumer 仍不创建；未来真实 consumer 必须使用 repository 返回的 mutation 建立
PUSH action，而不能绕过本 ADR 的 mask/transaction/source 契约。

## 后果

正面：

- 六项 local original operation 具备可保存、重启恢复的 Undo/Redo action 表达；
- false/0、handwriting explicit null 与 untouched fields 不再混淆；
- absent winner、并发 source mismatch、codec 腐坏和不可重新编码 state 均 fail closed；
- Undo/Redo 与原版一致地生成新 SET_METADATA，同时保留 Harmony operation-log 原子性。

代价与限制：

- NMD1 是 Harmony 本地 companion，不是原版同步格式；
- expected-source 是 Harmony 数据完整性适配，不能冒充原版逐行算法；
- 没有实际六项 UI consumer 时，本阶段只闭环历史基础设施和执行路径，不宣称设置体验已完成；
- 旧库、跨设备、NOTE_BUNDLE 和真实设备仍需后续验收。

## 验证契约

- 原版 hash/调用链必须由专项 Replay 固定；
- ArkTS fixture 覆盖六字段、mask、null/false/0、损坏 JSON、trailing bytes 和 wire-reencodability；
- PersistentHistory fixture 覆盖 materialize、PUSH→UNDO→REDO 与多 companion 拒绝；
- SQLite model 覆盖首次无 history 写入、absent winner、并发 mismatch、rollback、日志顺序和 revision；
- 全量 Replay、`git diff --check`、clean 后两套 HAP 必须通过；不得启动设备、模拟器、虚拟机、真机或 Hypium。

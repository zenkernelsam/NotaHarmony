# 原版 SET_METADATA 六项持久历史与撤销重做证据（2026-08-18）

## 1. 证据范围与只读基准

本阶段只研究原版 1.0.3 对 `SET_METADATA` 六项 preference register 执行 Undo 时如何读取当前值、生成逆向
operation，以及 Harmony 在已有本地出站 writer 上应如何建立可恢复历史。Desktop 目录只作只读 APK/JADX/
临时逆向证据源；所有 Harmony 代码、Replay、ADR 和 Report 均只写入正式仓
`C:\HarmonyProject\NotaHarmony`。

原版主源码位于：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

`vnf` 方法体过大，完整 JADX 输出在该分支会退化；本阶段复用 Desktop 临时简化输出
`C:\Users\Cisco He\Desktop\Notability\.codex-tmp-phase273-vnf-simple.java`。该文件不进入 Harmony Git，
但其 SHA-256 与关键行已由 Replay 固定。

| 文件 | SHA-256 | 关键位置 | 证明 |
|---|---|---:|---|
| `.codex-tmp-phase273-vnf-simple.java` | `01B9909A8979D966360432BAAE84E3E49CC64D18715F4561853D49A6A7281FD2` | 1390-1418 | `SET_METADATA` Undo 先按原 action 的 field presence 判断 touched register，再读取 NoteImpl 当前值，最后调用 `u5j.H(...)` |
| `u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | 245-247 | 当前值快照转发给 `xj2.d(...)`，构造一条新的 `l2d SET_METADATA` |
| `xj2.java` | `1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C` | 168-206 | 普通 nullable 参数为 null 时字段 omitted；boolean/layout/wrap 的 false/0 仍强制保留 presence |
| `dhh.java` | `393843AF7454BDEF6DD8A4B06679CDD6548E3296183944A89F9521E8A680B900` | 14-25 | handwriting `z2d` wrapper 可以存在而 inner string 缺席，能表达 explicit null |
| `er6.java` | `2B3A14557D9289DD6C5E66DA96DCB0B884129B4DDFFB0D988F73C758CDF12724` | 236-249 | NoteImpl 八个 register 均可由 nullable 初值建立 |
| `m09.java` | `3B6E92A54E7A5F15BB450A8B89A0A62ED25F2882D65F159595303CD29B6B214A` | 53-60 | 加载/空白构造链会把缺席的 metadata 值继续作为 null 传入 |
| `a79.java` | `FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13` | 52-59 | family/size/align/layout/wrap/handwriting 各自拥有独立 register |

## 2. 原版 Undo 结论

`vnf` 的 `SET_METADATA` 分支不是恢复旧 operation identity，而是：

1. 解出待撤销的 `l2d`；
2. 仅对该 operation touched 的字段读取 NoteImpl 当前 winner；
3. 把当前值交给 `u5j.H(...)`；
4. `u5j.H → xj2.d` 重新编码一条新的 `SET_METADATA`。

因此 Undo/Redo 必须留下新的、更晚的 original operation。旧 operation 只能说明动作语义，不能被重新插回日志或
复用旧 `(timestamp, siteId)`。

原版 wire 同时形成两个重要边界：

- handwriting 可通过 present wrapper + absent inner string 恢复 explicit null；
- align、family、size、layout、wrap 的 Java null 在 `xj2` 中意味着 omitted，不能表示“删除 winner 行”。

`er6/m09/a79` 又证明六项初始 winner 可以缺席。因此 Harmony 不能为缺席的普通 winner 猜一个默认值并把它写进
Undo history；这样的动作无法恢复原始缺席状态。

## 3. Harmony 映射与平台适配

Harmony 保持 original row 与本地历史 companion 分离：

- uploadable 行仍是原版 `ORIGINAL_SET_METADATA` envelope；
- 本地 `NMD1` companion 只记录 selected page、六位 touched mask、before/after 与 revision step；
- 原版行先 append，companion 后 append，但两者和 winner/revision 处于同一个 repository transaction；
- companion 不上传、也不推进文档 revision；Undo/Redo 每次仍生成新的 original row 与新的 companion effect。

对原版没有直接给出的并发边界，Harmony 采用明确的 fail-closed 适配：Undo/Redo 必须携带 touched-field expected
source；数据库当前 touched state 与它不一致时，整次事务拒绝，避免静默覆盖较新的本地或同步结果。未触碰字段不
参与比较，也不会被 operation 改写。

可逆性还要求：

- 无 history 的首次普通 winner 写入允许成功；
- 请求 history 时，任一 touched before winner 缺席则拒绝整个动作；
- handwriting winner 缺席与 winner-present/value-null 必须分开；
- before/after 不只要通过原版值域，还必须能被生产 `encodeOriginalSetMetadataFields()` 再编码，提前拒绝超长或
  非 UTF-8 round-trip 的不可恢复 state。

## 4. Replay 与 fixture

- `docs/migration/replays/d02-original-set-metadata-history.mjs`：固定上述原版 hash/调用链，检查生产源码顺序，
  并以独立 SQLite 模型验证首次写入、absent winner、PUSH→UNDO→REDO、并发 source mismatch、事务 rollback、
  operation-log 顺序与 revision 语义；结果 `TOTAL=32 FAILED=0`。
- `note/src/test/NoteMetadataMutationCodec.test.ets`：覆盖六字段 round-trip、explicit null、false/0、subset mask、
  ordinary absent、非法值、恶意 JSON、trailing bytes 与不可重新编码 state。
- `note/src/test/PersistentHistory.test.ets`：覆盖 metadata materialization、durable PUSH→UNDO→REDO 和多 companion
  action 拒绝。

## 5. 明确未闭环项

本证据闭环的是六项 original local writer 的 durable history 基础设施，不等于已经证明以下 consumer：

- PAGELESS 页面/缩略图布局；
- align-to-lines、handwriting recognition provider、default-font inheritance、block-wrap UI/渲染；
- 真实旧库、多设备/服务端同步、`NOTE_BUNDLE` round-trip；
- 设备上的设置入口、撤销手感、像素、性能与错误提示。

没有原版调用图或设备证据时，不在本阶段猜造这些行为。

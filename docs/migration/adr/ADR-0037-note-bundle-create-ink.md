# ADR-0037：NOTE_BUNDLE CREATE_INK 同事务内容回放

- 状态：Accepted（最终可见页面的 CREATE_INK 子集）
- 日期：2026-08-11
- 关联：D-02、ADR-0011、ADR-0012、ADR-0026、ADR-0036

## 原版证据

原版 NOTE_BUNDLE 的 operation vector 保存 operation identity、client/server time、payload type 与嵌套 payload table；
嵌套 CREATE_INK 仍是 `dm2`，不是另一套 snapshot 格式。`dm2` 的 page/origin/rotation/scale、tool/style、color、
width、center/custom/fill path、fill color、style map、z-index、nib 与 effects 校验和实时 operation 完全相同。因此 bundle
内容必须复用实时 inbox 的 decoder、资源预算、工具门禁、确定性 Pencil splat、层序和页面 revision 物化，不能复制一份宽松
decoder，也不能伪造外层 FlatBuffer bytes 再走 root parser。

`dm2.a()` 还证明：非 Tape 不能带 TapePattern，effects 只允许 Pen/Highlighter，非零 effect center path 只能有一个
component。`ife` 给出 TapePattern 的完整 wire 值 `STRIPES/GRID/DOTS/PLAIN/STARS/FLOWERS/HEARTS/WAVES/CHECKERS = 0..8`，
`qfe` 则按图案、前景/背景色和缩放生成重复 tile。现有 Harmony `RenderSpec` 没有 Tape 工具/图案持久化字段；这属于
Phase 1 笔画契约变更，不能把 Tape 压成普通 Pen 或只保存枚举后假称完成。

## 决策

`OriginalCreateInkOperationApplier` 新增 table-level `preflightTable/applyTable`，两者直接消费 NOTE_BUNDLE 已解析的 child
table，并与实时 `apply()` 共用同一 `applyPayload()`。不构造或解析伪造的 root FlatBuffer。合法 Pen/Pencil/Highlighter
CREATE 继续复用现有路径、transform、auxiliary path、style map、Pencil splat、z-index、live snapshot 与搜索失效逻辑。

整份 bundle 在首次页面写入前预检所有非页面 payload。当前只放行 CREATE_INK；未知/后续内容类型、Tape/effects、缺页、
最终已归档目标页，以及含 entity delete/undelete 的 DELETE_ENTITIES 都返回具体 NOTE_BUNDLE deferred reason。后者必须门禁，
否则“先创建 Ink、后删除 Ink”的 bundle 会错误保留内容。

页面身份 bootstrap 与 CREATE_INK 在 `DeferredSyncedOperationBundleStore` 的同一 SQLite 事务内完成。过去 bootstrapper 返回
deferred 时外层仍会 commit；现改为显式 rollback，因此第二支 Ink 的页面/层序分歧、资源超限或任何异常都不会留下页面身份、
第一支 Ink、部分 register 或错误 revision。

重复 bundle 允许幂等 no-op，但只有 `original_element_z_index` 与 `original_ink_state` 同时存在，且不可变 CREATE baseline
（base/auxiliary paths、fill/style map、初始 transform/page/z-index，以及尚无 MODIFY winner 的 style/color/width）与输入一致时
才成立。重复检测在目标页查找前执行，所以元素后来跨页、删除或页面归档后仍能识别同一 CREATE；部分状态或相同 identity 的
冲突内容会抛错并回滚，不以“已存在”掩盖数据库损坏或远端冲突。

## 验证

- `SyncedOperationInbox.test.ets` 新增真实 NOTE_BUNDLE child CREATE_INK table，直接执行 table decoder 与 preflight。
- `d02-note-bundle-create-ink.mjs` 覆盖两支 Ink、uint64 z-order、revision、重复幂等、冲突 identity、未知 payload、Tape、
  缺页、entity visibility 零写入，以及内容中途失败的页面身份/Ink/snapshot/revision 全回滚。
- 全量 D-02 Node/SQLite replay：`TOTAL=46 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`；未启动设备或执行 Hypium。

## Deferred 边界

本阶段只关闭最终可见页面的 NOTE_BUNDLE CREATE_INK。归档页内容、entity visibility、ADD_PATH_ELEMENTS、MODIFY_INK、
CREATE/MODIFY_BLOCK、富文本字符/样式、NOTE_BUNDLE background fallback、Tape/effects、公式引擎、认证 transport 与服务端
note/site 创建仍未关闭。下一步应沿同一 table-level preflight/apply 边界逐类加入，并保持整批零部分写入。

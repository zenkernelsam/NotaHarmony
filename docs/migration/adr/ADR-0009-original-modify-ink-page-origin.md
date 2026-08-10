# ADR-0009：原版 MODIFY_INK page/origin 组合 register 与跨页搬运

- 状态：Accepted（page/origin 受证明子集）
- 日期：2026-08-10
- 关联：D-02、数据库 v31、ADR-0008

## 背景

原版 `wd8` field 1 是 12-byte `cxc(SeqId)`，field 2 是 8-byte `fqa(Point)`。`q06.c()` 只有在二者同时存在时才把
`(page,origin)` 作为一个值写入 `pageAndOriginRegister`；只有一个字段时忽略该对子，但同 payload 的其他 register 仍正常参与 LWW。
该 register 与 rotation、scale、z-index 分离，初始 winner 同样为空，读取默认值来自 CREATE_INK。

page 改变不只是 transform 更新。Harmony 将页面内容物化到 live `page_element_snapshot` 或删除页
`original_deleted_page_element`，另以 `original_element_z_index` 保存原版 page 与 z-index。只改其中一处会造成重启后丢笔迹、
恢复删除页时重复元素，或画布顺序与同步状态分叉。

## 决策

数据库升至 v31，在 `original_ink_state` 中保存 CREATE page 基线，以及 page/origin 的 value、winner identity 和 winner-presence。
新 CREATE 直接写入基线；旧 v30 行首次 winning page/origin 或后续 transform 修改时，从保留的 CREATE_INK envelope 恢复。

`OriginalModifyInkOperationApplier` 开放 field 1/2，并遵循：

1. page/origin 只组成一个 register；字段不完整时按原版忽略，不误判为两个独立修改。
2. 当前 page 必须同时与 register/CREATE fallback、`original_element_z_index` 和实际 live/archive storage 一致；目标页必须已绑定且
   恰好存在于 live 或 archive 一侧。
3. 跨页前读取源/目标页全部原版 z-index 成员，并与实际存储成员双向核对。所有 Ink 和页面均预检后才进行任何写入。
4. winning move 保留 z-index，把更新后的 Stroke payload 搬到目标 live/archive 表，按 `(uint64 zIndex, uint32 timestamp,
   uint16 site)` 重排两页；源/目标页各推进一次 content revision 并失效 Ink 搜索。
5. origin 与当前 winning rotation/scale 共同重建完整 transform 和 bounds，不从旧矩阵反解分量。同页 origin 修改只推进该页一次。
6. 远端 reducer 仍不写本地 operation log 或 Undo；任一 payload、页面、顺序、transform 或 revision 分歧由外层 inbox 事务整体回滚。

## 后果与验证

- 支持 live→live、live→archive、archive→live，以及多 Ink 同操作跨页；页面可为空，原 z-index 和稳定 Ink identity 保持不变。
- 较小 op ID 的首次 page/origin 修改获胜；真实 winner 建立后保持严格 unsigned `(timestamp,site)` LWW。
- `d02-modify-ink-page-origin.mjs` 覆盖真实 field 1/2、partial pair、v30→v31、首写、三类存储搬运、同页 origin、既有
  rotation/scale、双页 revision、z-order、缺目标/顺序分歧、多 Ink 原子性、故障回滚和无本地日志。
- z-index register、辅助路径、Pencil/Tape/effects 与后续内容 payload 仍未完成；未执行设备 Hypium，不据此关闭完整
  MODIFY_INK 或 D-02。

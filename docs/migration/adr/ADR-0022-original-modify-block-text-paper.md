# ADR-0022：原版 MODIFY_BLOCK TEXT paper 与 resize 寄存器

## 状态

已接受，D-02 Phase 43。

## 原版证据

- `td8.java` 的 18-field `ModifyBlock` accessor 中，field 13（vtable offset 30）由 `t()` 读取为 `n2d SetPaper`，field 16（vtable offset 36）由 `v()` 读取为 nullable `Boolean resizesWidthToFitText`。
- `n2d.java` 的 field 0 是 nullable `k3a value`。因此 SetPaper wrapper 存在而 value 缺席不是“没有修改”，而是显式清除 paper。
- `bie.java` 在 TEXT block 路径中把 `td8.t().j()` 交给独立 `fqb` register；`qy0` 只承载 BlockCommon。paper/resize 不得与 common geometry、corner、textWrap 或 caption 共用 winner。
- CREATE_BLOCK 的 paper 与 resize 只是无 winner 时的读取 baseline；首次 MODIFY_BLOCK 必须按自身 `(timestamp, site)` 获胜，不能把 CREATE op 身份伪造成初始 winner。

## 决策

1. `OriginalModifyBlockPayload` 解码 field 13 的 SetPaper wrapper 和 field 16 的 nullable boolean；fields 10/11/12/14/15 继续保持具体 unsupported 门禁。
2. `original_block_state` 为 paper 和 resize 各保存 value、winner timestamp、winner site 与 winner-present。数据库升至 v41，v40→v41 只追加八列，不改写 CREATE baseline。
3. paper wrapper 缺席表示 no-op；wrapper 存在且 value 缺席表示 winning clear。clear 后旧 op 不得恢复旧 paper，较新的 SetPaper 可以重新设置。
4. paper 与 resize 分别执行严格 LWW。没有 winner 时读取 `create_text_paper` / `create_resizes_width`；winner 存在时读取 register value。
5. live element、删除页 archive snapshot、搜索失效和 register state 在同一事务物化；任一步失败均回滚，不能留下快照与 winner 撕裂。

## 验证

- `d02-modify-block-text-paper.mjs` 使用真实 `td8`/`n2d` FlatBuffer 形状，覆盖 paper 设置、显式 clear、resize、CREATE fallback、两个独立 LWW、stale no-op、live/archive snapshot、故障回滚和真实 v40→v41 SQLite ALTER migration。
- 全部 32 个 D-02 Node/SQLite replay 通过。
- clean 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。

## 限制

本阶段只关闭 TEXT 的 MODIFY paper/resize register。ROUND corner 像素裁剪、编辑态 resize-to-fit 精确宽度回写、RTL/复杂 shaping、IMAGE/MATH block、Pencil/Tape/effects、NOTE_BUNDLE 内容和完整 D-02 仍未关闭；设备 Hypium 未执行。

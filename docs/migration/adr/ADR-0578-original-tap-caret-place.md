# ADR-0578 — 文本块按下点光标定位（ttc → qke + sqa）

- 状态：Accepted
- Phase 609；对齐 `dl1`/`uw2`/`uke`/`qke`/`sqa`/`rej.i`/`zn9.f`
  （decompiled_1.0.3）。

## 背景

原版已选中的文本块被再次点按（`dl1` case2 itc 分支产出
`ttc(blockId, jE)`）时，`uw2` case4 先以 `qke` 激活该块文本
编辑器（`uke.p` 挂起会话恢复），随后**无条件**派发
`sqa(rej.i(zn9.f(j, transform), layout), 0)`——把按下点
逆变换进块局部系、命中布局偏移，光标落在按下字符处；`tqa`
对命中点做链接探测。gtc 组选区内命中非文本成员亦产出 `ttc`
（消费不拖拽）。

Harmony 旧实现：`insideOverlayElementTap` 已覆盖 itc→编辑
激活与 gtc 成员消费的结构（Phase 593/603），但
`beginTextEditingAt` 只恢复 `suspendedCaretByBlock` 挂起光标，
无会话时由 TextArea 默认落位——不按按下点定位，丢失 sqa 的
"光标跟手"语义。

## 决策

1. `Canvas2DTextRenderer.caretIndexAtPoint`：rej.i /
   `getOffsetForPosition` 等价实现，与 `linkAtPoint` 共用
   `inverseTransformPoint`/`layoutLines`/`characterIndexAt`：
   - y 轴钳到**最近**行带（行带上/下方按距离取最近行），
     对应 sqa 的最近行定位而非 linkAtPoint 的带内才命中；
   - x 轴行内 `characterIndexAt`（半字宽拆分），越过行尾
     （返回 null）钳到 `line.end`；
   - 空文本 → 0；逆变换失败 → null（调用方保留原光标）。
2. `beginTextEditingAt`：qke 恢复挂起光标（既有）后立即计算
   `tapCaret`，非空则覆盖 `textEditingRestoreCaret`/
   `editingCaretOffset`——sqa 无条件定位语义（按下点光标优先
   于挂起会话光标）。该函数同时服务 `insideOverlayElementTap`
   （itc→ttc 等价）与 TEXT 面点按路径，两路径原版均经
   sqa 定位。
3. `TextBlockOverlay.onAppear` 既有
   `caretPosition(min(restoreCaret, len))` 消费不变。
4. 链接命中（`linkHitOnTextBlock`，tqa 等价）保持先于编辑
   激活——点中链接开菜单，不进编辑。

## 偏差

- `rej.i` 的确切行选择策略（最近行 vs 首命中行带）在
  decompiled 源码中不可见；按 Compose `getOffsetForPosition`
  的最近行钳制语义实现——按在块内文本下方空隙定位到末行
  行尾，与原生体验一致。
- gtc 组内非文本成员的 `ttc` 在原版走 `qke`（无 ake → 记日志
  并置空）；Harmony 以"消费不拖拽"等价，不模拟日志副作用。

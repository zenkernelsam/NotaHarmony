# ADR-0240：原版剪贴板事务、Paste 锚点与可达 Group 子图

## 状态

Accepted - Phase 262（2026-08-17）

## 背景

早期 M2-R-08 已把“Copy 立即复制进文档”改为会话剪贴板，并逐步支持 Stroke、Shape、Text、Image、Math、统一
z-order 与原版 Group 复合 Paste；但仍遗留三类关键偏差：

1. 普通 Paste 按 sequence 固定偏移 20/40/60，而原版使用用户请求的文档位置；10%/最多 30 的偏移属于
   Duplicate。
2. Copy preparation 立即覆盖已发布 clipboard；Cut 先修改 UI/history，再调用会吞同步 queue 异常的
   `persist()`，删除失败可能仍发布新 clipboard。
3. Group Copy 验证整个 `selectionGroups`，一个无关损坏 Group 会阻断独立选择；Paste preparation 只由 sequence
   标识，不能证明异步期间 clipboard 未被新 Copy 替换。

另外，Paste 曾以独立固定按钮出现，菜单可用性没有同时受 loaded/current page identity 与 history busy 状态约束。

## 原版依据

- `lg2.d()`：完整 CopyResult → `x82.I()` 删除成功 → `mg2.a` 发布。
- `lg2.g()/c()`：只递归本次 selection 中 top Group 的可达后代，生成顺序 child-before-parent。
- `w43/v49/t39/lg2.f()`：Paste command 携带用户请求的文档位置，并相对源 bounds center 平移。
- `cg2.a()/lg2.b()`：10%、最多 30 的错开放在 Duplicate 路径，不是普通 Paste。
- `g39.a()/b()`：请求开始后约 200ms 内抑制并发 Paste。
- `lg2.d()` 删除 selection leaf IDs，没有主动删除 Copy graph 中的 Group records。

完整片段、哈希与边界见
`docs/migration/evidence/original-clipboard-transaction-anchor-jadx-2026-08-17.md`。

## 决策

### Copy/Cut 发布协议

- `StrokeClipboard.prepareCopy()` 深复制全部选中元素、element order 和可达 Group 图，但不修改已发布 clipboard。
- `commitPreparedCopy()` 只接受当前 preparation token；成功后原子替换 snapshot、重置 Paste sequence 并推进
  clipboard revision。失败/取消保留旧 clipboard。
- Copy 立即 prepare+commit；Cut 先 prepare，再构造删除后的完整页面数组、element order、Undo action 和
  prepared history。
- Delete/Cut 调用 `queueSaveElements()` 成功前不改元素数组、selection、history 或 clipboard。同步 preparation/
  enqueue 失败时取消 Cut preparation并原地返回；成功后才发布 Cut clipboard、应用数组和 push history。
- Group records 不因叶实体被 Cut/Delete 而清理；这是原版 type-25 可见性与 Undo 恢复 Group identity 的必要条件。

### Paste preparation 与几何

- `preparePaste()` 只构造候选，不消费 sequence；`commitPreparedPaste()` 同时核对下一 sequence 与
  clipboard revision。
- 普通 Paste 的平移为 `targetCenter - sourceBoundsCenter`，随后按页面 8 单位边距对整个 bounds clamp；连续 Paste
  到同一位置具有相同几何，但仍生成新 ID。
- 原版 Group Paste 继续使用 durable `commitOriginalClipboardPaste()`；普通 Paste 先严格验证新 element order，
  再 enqueue prepared history，成功后才提交 sequence、UI 和 history。
- 移除普通 Paste enqueue 后的第二次 `persist()`，避免同一动作重复排队并改变 action boundary。

### Group 与 UI

- `copyOriginalGroupGraph()` 只验证 selected top roots 的可达子图；可达重复 ID、环、缺成员、多父、空 Group、
  Group/leaf ID 冲突和非根 top Group继续 fail closed，无关损坏 Group 不参与本次 Copy。
- Selection Overlay 不再绘制固定/独立 Paste 按钮；Paste 仅作为原生 selection menu item 出现。
- 画布长按保存 canvas-space anchor并绑定 ContextMenu；选区菜单使用当前 selection bounds center。
- `canPasteClipboardNow()` 同时要求实际内容、loaded、无 loading/failure、无 history busy、loaded/current page 相同。
- 使用原版 200ms 并发抑制；它不参与 Paste 几何。

## 后果

- Cut 的同步预检/排队失败不再删除 UI 或覆盖用户此前的 clipboard。
- Paste 队列失败不会消耗 sequence；新 Copy 会使旧 prepared Paste revision 失效。
- 连续 Paste 不再逐次漂离用户长按位置，跨尺寸页面仍保证整体尽可能落在安全边距内。
- 一个无关损坏 Group 不会瘫痪整页 Copy；真正被复制的 Group 图仍保持严格原版身份和层级约束。
- 会话 clipboard 仍在离开编辑器时清空，不宣称跨应用重启持久化；系统图片 clipboard 也不属于本阶段。

## 验证契约

- `StrokeClipboard.test.ets` 覆盖 unpublished Copy、取消 Cut preparation、普通 Paste 未 commit 不消费 sequence、
  新 Copy 使旧 Paste revision 失效、同目标连续 Paste、edge clamp 与无关损坏 Group。
- `d02-original-clipboard-transaction-anchor.mjs` 固定原版事务/锚点/200ms/Group 证据和 Harmony queue-before-apply
  顺序；专项 `TOTAL=23 FAILED=0`。
- 更新单元素、Group UI 与 Group protocol 三份旧 replay，移除 20×sequence 几何假设。
- clipboard/Group/history/z-order 相关 replay、全量 replay、clean 后两套 HAP 与 `git diff --check` 必须通过。

## 仍需设备验收

- Canvas `bindContextMenu(LongPress)` 与 Pen/Eraser/Selection 手势优先级及是否产生短暂墨迹。
- 长按菜单锚点、页面边缘菜单位置、200ms 快速连击反馈和连续 Paste 选择恢复。
- 跨页 Paste 后保存/返回/Undo/Redo；Group、Image、Math、富文本的像素与资源结果。
- 系统图片 clipboard 是否作为后续产品能力接入，以及跨编辑器/跨重启 clipboard 生命周期决策。

# ADR-1410：Ctrl+Shift+M/I 键盘插入和弦复用工具栏插入管线

## 状态

已接受（Phase 1475）。

## 背景

原版 `f2.java:240-247`：Ctrl+Shift+M → `ea1.p(mc8.a)`（InsertMath）、
Ctrl+Shift+I → `ea1.p(nc8.a)`（InsertPhoto）。两事件进 `ea1` 事件
总线，由编辑器消费端打开数学插入 / 图片导入 UI。

## 决策

不在 Harmony 侧新建插入管线。`NotePage` 已有
`mathInsertSignal`/`photoInsertSignal` 信号与工具栏
`onInsertMath`/`onInsertPhotos` 消费端；键盘支仅新增
`onKeyInsertMath`/`onKeyInsertPhoto` 回调直通同一管线，并复用
同一租约门集（`photoImportLeaseActive`/`pageOperationBusy`/
`historyPending`/`pageStructureLeaseActive`）。

## 依据

- 原版两支为**消费触发**（发事件），消费端即插入 UI——Harmony
  信号管线语义等价；
- 同管线保证工具栏与键盘两条入口行为一致（门控、泄漏、回放
  校验同一份）；
- 事件总线的解耦在单 Page 内无收益。

## 后果

- 键盘触发与工具栏触发的插入行为完全同构；
- `u7b.g` 组合旗不移植（恒真近似，与 P1468 登记一致）；
- DOWN 消费不动作，与原版一致（支内无 `b2=0`）。

# ADR-0896 — `vej` 完整面：RemoveChars 工厂 + 光标移动契约

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`vej` 双重职责：

1. **线协议**：`a(list,qo5)`=RemoveChars 工厂（builder 序列化→
   `d()` 反读→`ybg.c` 校验→`rh8.q` 归还），与 `q` 写器字段序镜像。
2. **光标数学**：`b`–`r` = `{paraIdx,offset}`(hqe) 在 `ti3` 多段布局上的
   完整键盘导航——行上下（di3 remembered-x）、grapheme 左右
   （BreakIterator）、词左右（跳 cq.f0 空白）、段首尾、判空。

## Harmony 决策

- `a`/`q` 序列化对：等价（Replay 覆盖）。
- `b`–`r`：**平台委托**。Harmony 文本编辑走原生 TextArea +
  扁平 `caretOffset`，方向键/词跳跃由系统处理；`{para,offset}`
  双维导航无对应布局需求。若未来自绘文本布局，用
  `Intl.Segmenter`(grapheme/word) 重建等价 BreakIterator 语义。

## Parity 状态

线协议等价；光标层为平台差异（非缺陷）。

## 验证

- `d02-vej-cursor-helpers.mjs`：22/22 通过。
- 全量 Replay 825 文件绿，见 Phase 952 提交。

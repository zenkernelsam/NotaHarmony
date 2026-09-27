# ADR-0884 — rl2 CreateBlock 字段图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

21 槽：变换头{type:cz0,corner:ty0,page:cxc,
origin:fqa,rotation,scale,size:qed 必需}+
内容组{textWrap,enableCaption,zIndex,image,
cropRect,webUrl,mathLatex,mathColor,paper}+
变换尾{flip×2,resizeToFit,margins,positionLocked}。

## Harmony 决策

字段布局对齐；必需 size 缺失拒绝。

## Parity 状态

等价。

## 验证

- `d02-rl2-block.mjs`：22/22 通过。
- 全量 Replay 813 文件绿，见 Phase 940 提交。

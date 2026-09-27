# ADR-0829 — `x09`/`a79` 物化文档模型

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `x09` = 标记接口（伴生 m09）；`a79 implements x09` =
  物化文档模型，u5j 工厂经 `(a79)x09` 具体字段消费。
- 八 `yc6` LWW 寄存器：七具名属性（KProperty 实证
  title/defaultFontFamily/defaultFontSize/alignTextToLines/
  layoutMode/blockWrapSupport/handwritingLanguage = l2d
  SET_METADATA 面）+ `K` 背景寄存器（winner nz9 缺省 Q）。
- `f: f1a` = 序列/实体模型（rvb 序源 + cl2/oja/q07/kia
  索引族）；`B: m4c` = 富文本物化态。
- 静态默认：N=qed(612,792) Letter、O=36pt 边距、
  P=72dpi、Q=tu1 色纸背景。

## Harmony 决策

物化 note 态与 SET_METADATA winner 字段 ↔ 寄存器组；
Letter 默认页/边距/背景 ↔ PageBackgroundModel/NoteTypes。

## Parity 状态

等价（模型结构与默认值逐项对齐）。

## 验证

- `d02-document-model.mjs`：21/21 通过。
- 全量 Replay 与双 HAP 构建见 Phase 885 提交。

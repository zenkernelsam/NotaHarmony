# ADR-0242：原版 Shape 富寄存器与语义渲染闭环

## 状态

Accepted - Phase 264（2026-08-17）

## 背景

M2-R-10 已经让 LINE、ELLIPSE、POLYGON 作为独立 `ShapeElement` 进入统一元素序列，但原版 Shape 的完整状态和
渲染边界仍未闭环：CREATE_SHAPE 只编码部分字段；ModifyShape 可能在部分 register 更新后先写 journal；Tape、
force、smart-highlight、effect/tint 在持久化、Clipboard 或 Partial Eraser 中丢失；Pencil Shape 没有使用原版
确定性散布；带箭头的曲线 LINE 又会被重新画成固定采样折线。

完整原版证据见
`docs/migration/evidence/original-shape-rich-registers-rendering-jadx-2026-08-17.md`。

## 决策

### 完整 Shape 状态

- `ShapeElement` 保留 `originalTapePattern/originalSmartHighlight/originalForce/originalInkEffects/
  originalInkEffectsTinted`，clone、识别、持久化、Clipboard、导入导出和 reducer 不得删减。
- CREATE_SHAPE 使用 18 字段、84-byte object、8-byte alignment；uint64 effect 使用十进制字符串保真。
- ModifyShape 先将所有 LWW winner 应用到候选 state，再对最终组合统一验证；验证成功后才写 modification journal。
- fill alpha、style、Tape enum、force、effect/tint/tool coupling、Polygon 顶点数及 LINE 定义必须在 encoder、reducer、
  persistence 和 package validation 保持一致。

### 识别和 Clipboard

- 原版 CREATE_SHAPE 不接受 VARIABLE_WIDTH。识别到 Shape 时 style=0 降级为 FIXED_WIDTH=1，并保留单元素
  `originalCreate` reservation；多元素识别仍不得复用一个 operation identity。
- Clipboard 复制保留 Tape/force/effect/tint；smart-highlight 重置为 false，reserved create identity 清空；仅存在于
  legacy `originalCreate.averageForce` 的 force 先提升到稳定字段。

### 语义 Path 和渲染

- LINE 保留 line/quadratic/cubic verb；Ellipse 使用四段 cubic；Polygon 无条件按原版 ShapeDefinition 闭合。
- 箭头主干按弧长定位参数后，用 de Casteljau 截取原 quadratic/cubic，而不是把采样点重画为折线；箭头保留独立
  子路径。
- Pencil Shape 使用固定 fallback seed，主干和箭头各自重置；force 来自稳定 register 或 create averageForce。
- Pencil splat cache 上限为 32 Shape、262144 splat，几何或宽度变化失效，编辑器/缩略图 dispose 时清空。
- Highlighter Shape 使用原版 alpha 107。
- Shape 的 Tape register 继续保存，但非 Pencil Shape renderer 不调用 Ink Tape pattern；只有 Partial Eraser 转换成
  Ink 后才由 Ink consumer 使用该 register。

### Bounds 与 Partial Eraser

- Shape bounds 使用原版保守 definition box、stroke 扩张和箭头尺寸，不用采样点极值替换身份几何。
- Shape Partial Eraser 产生 Ink 残片时保留 force、Tape、effect 和 tint，继续遵守已有 Group replacement、层序和
  Undo/Redo 原子契约。

## 后果

- 保存重启、复制粘贴、原版 operation round-trip 不再静默丢 Shape 渲染寄存器。
- 本地识别不会产生原版无法编码的 style=0 Shape。
- 曲线箭头主干在普通 Shape 和 Pencil Shape 中都保留原曲线，而不是固定 64 段可见折线。
- Tape 来源 Shape 的外观与原版一致：保留可编辑/可转换状态，但 Shape 本体没有额外图案叠层。
- Pencil cache 生命周期与 renderer 生命周期绑定，不在多次进入编辑器或缩略图 worker 退役后继续占用 JS 内存。

## 验证契约

- ArkTS fixture 覆盖 18 字段 round-trip、严格 package/persistence、ModifyShape winner 顺序、Clipboard、Partial
  Eraser、variable-width 降级、原生 Path verb、曲线箭头、Highlighter alpha、Pencil seed/cache 与 Polygon 闭合。
- `d02-original-shape-rich-registers-rendering.mjs` 同时读取 `ao2/le8/k16/p16/y4d/xai/l96` 与 Harmony consumer，
  锁定寄存器、Tape renderer 边界、Path 与生命周期。
- Shape/Clipboard/Partial Eraser/package 相关 replay、全量 replay、`git diff --check`、clean 后两套 HAP 必须通过。

## 仍需设备验收

- Pen/Highlighter/Pencil/Tape 来源 Shape 的主画布与缩略头像素。
- 直线、quadratic/cubic 箭头的端点、缩放、旋转、选区和擦除。
- 保存重启、复制粘贴、Undo/Redo、原版导入导出和 Partial Eraser 后的 Ink Tape 图案。
- 32 项/262144 splat 上限下的长时 JS/native 内存与绘制帧时。

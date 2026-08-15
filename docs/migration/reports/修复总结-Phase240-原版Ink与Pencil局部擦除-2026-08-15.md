# Phase 240 修复总结：原版 Ink 与 Pencil 局部擦除

## 本阶段目标

在 Phase 237–239 已完成的实体 replacement、Group、Shape、持久 Undo/Redo 与 mixed order 管线上，严格按
Notability Android 1.0.3 的 `jt1 → n8j → o8j → u5j` 补齐普通 Ink、Pencil、Dash/Dots、显式
custom path 与 fill path 的局部擦除语义；不得继续使用旧 `EraserEngine` 的中心线近似破坏原版几何和
Pencil 稳定状态。

## 原版结论

- `jt1` 分别向 `n8j` 提供 attributed center、nullable explicit custom 与 nullable fill，并把 eraser
  逆变换到 Ink 局部坐标。
- `n8j.e()` 只用 eraser fill 裁 center，不按 Ink 半宽扩大命中；custom 缺席时才从 center 生成 outline，
  fill 仅在 fill color 存在时参与。
- `o1/ft1/cfa` 对 Pencil 使用 `2.84 × baseWidth` 的视觉 outline，但用基础宽度沿 center prefix 推进
  随机 seed 和最后 splat reference。
- Dash/Dots 在 remnant 起始距离推进 phase；物化后的 style entry 清零 Pencil 字段，只保留推进 phase 与
  源 period。
- `n8j/o8j` 会物化 custom-only、fill-only 等每个可见 component；fill-only remnant 也必须能再次擦除。
- AudioLinked Ink 按 retained center 在源路径中的距离比例重算 start/duration；没有 center 的 fill-only
  component 保留完整区间。
- path、boolean、style supplier 或 CREATE_INK materialization 失败表示 Unchanged；只有空结果才表示完整
  删除 source。
- 详细证据、恢复位置与 SHA-256：
  `docs/migration/evidence/original-ink-partial-erase-jadx-2026-08-15.md`。

## 已完成修复

1. 新增 `OriginalInkPartialEraser.ets`，使用 ArkGraphics2D `drawing.Path`、`Pen.getFillPath()` 与
   `Path.op(DIFFERENCE/INTERSECT/UNION)` 在 Ink 局部坐标执行原版式裁切，不再把 PARTIAL 模式交给旧
   `EraserEngine`。
2. center 使用 native `getLength/getPositionAndTangent/getSegment`，保留 line/cubic 几何及裁切边界的
   width/pressure/altitude/azimuth 属性；边界以 20 次二分定位，单点 Ink 继续按 round circle 处理。
3. explicit custom 优先；缺席时才按 center 与 attributed width 构建 outline。Pencil outline 使用原版
   `2.84 × brushWidth × widthFactor`，而非普通笔宽或固定宽度近似。
4. custom、fill 与 center 分别执行 difference，再按 union 后的可见 component 归属 center fragments。
   fill 仅在 `fillColor != null` 且 fill path 存在时参与。
5. fill-only component 使用 MOVE-only custom sentinel 表达空 outline，并修复二次擦除：sentinel 不再被误判为
   path conversion 失败。
6. `PencilSplatGenerator` 新增 `generateWithState()`、最终 seed、最终 reference 与 emitted 状态；现可按源
   style entry 重放裁切点之前的 center prefix，并以边界状态稳定生成 remnant splats。
7. Pencil remnant 的 style map 只保留 Pencil seed/reference，Dash 寄存器清零；Dash/Dots remnant 只保留
   推进后的 phase 与源 period，Pencil 字段清零。非 pattern 的被切 component 省略原版全零 entry。
8. `StrokeCanvasPainter` 在画 Pencil splats 前使用 remnant explicit custom path 建立 clip，避免随机纹理越过
   boolean clipping 的真实边界；fill 仍走共享 Ink fill renderer。
9. AudioLinked remnant 根据 `[startDistance,endDistance] / totalDistance` 重算时间，使用十进制字符串安全移动
   uint64 start，并限制 duration 为 uint32。
10. remnant 保留 source transform、color、Highlighter、effects/tinted、Tape pattern、style 与 fill color；
    bounds 同时覆盖 center cubic、custom、fill 与 transform。
11. `validateOriginalPartialErasePlan()` 解除对 Pencil source 的错误拒绝，Pencil 现可进入与普通 Ink 相同的
    CREATE_INK remnants、Group replacement、DELETE_ENTITIES、search、Undo/Redo 事务管线。
12. 新增 `validatePartialEraseMaterializationPlan()`。本地 snapshot fallback 在删除 source、修改 Group 或写
    history 前，也必须预检全部 remnant 可编码为 CREATE_INK；original preflight 失败不再被误解释成“改走
    本地删除”。任一 remnant 无法物化时整次手势保持 Unchanged。
13. 对 center samples、components、auxiliary path elements 与 Pencil splats 设置硬预算；奇异 transform、
    PathOp、iterator、segment、style 或 materialization 失败均 fail-closed，不产生 source deletion plan。
14. `NoteCanvasView` 的 PARTIAL 模式已真实接入 `OriginalInkPartialEraser`，Shape 继续使用 Phase 239 的
    `OriginalShapePartialEraser`；两类 replacement 仍按 mixed element order 合并提交。

## 边修边审额外捕获的问题

- Pencil outline 初版只乘 `2.84`，遗漏逐点 `widthFactor`；已改为 attributed outline。
- fill-only remnant 初版使用 MOVE-only sentinel 后，二次擦除会把它误当无效 custom path；已把空 outline 与
  conversion failure 分开。
- 裁切后的 style-map 初版会保留与当前工具无关的 Pencil/Dash 字段；已按 `vyd/uyd` 物化语义清零。
- canonical preflight 失败后旧 UI 会直接进入 local fallback，可能删除一个无法持久化的 source；现增加
  fallback materialization preflight。
- clean `note@default` 构建发现 Dash/Dots phase 初版引用作用域外的 `startDistance`；已改为
  `center.startDistance`，并在专项 replay 固化该边界。增量 ohosTest 曾未暴露此错误，最终结论以 clean
  主模块构建为准。

## Fixture 与 replay

- 新增并注册 `OriginalInkPartialEraser.test.ets`，覆盖：
  - center 不按半笔宽扩大；
  - native cubic 与边界属性插值；
  - explicit custom/fill 独立裁切及 fillColor gate；
  - Pencil `2.84 × widthFactor`；
  - Pencil seed/reference 推进与 splat 稳定重建；
  - Dash/Dots phase 与无关字段清零；
  - AudioLinked retained-distance timing；
  - transformed Ink、effects 与 Tape；
  - fill-only remnant 二次擦除；
  - single-point 与 singular transform fail-closed；
  - Pencil painter custom clipping。
- 扩展 `StrokePersistence.test.ets`，证明 local source identity 可进入 fallback preflight，但不可编码的
  remnant 会在 source 删除前被拒绝。
- 新增专项 replay：
  `originalInkPartialEraser=local-center-custom-fill-pencil-state-dash-audio-fill-only-fail-closed`。
- 全量桌面 replay：`REPLAY_FILES=225 FAILED=0`。
- `git diff --check`：通过；仅有项目既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 942 ms`。
- clean 后 `note@ohosTest` HAP：`BUILD SUCCESSFUL in 7 s 129 ms`。
- clean 后 `note@default` HAP：`BUILD SUCCESSFUL in 30 s 272 ms`。

## 决策与文档

- 新增 `ADR-0217-original-ink-partial-erase.md`，记录 center/custom/fill、Pencil state、fallback
  materialization 与失败语义。
- 新增 `original-ink-partial-erase-jadx-2026-08-15.md`，固化 `jt1/n8j/o8j/o1/ft1/cfa` 证据与
  原文件哈希。
- 新增 `d02-original-ink-partial-eraser.mjs`，把生产接线、原版证据、fixture 注册、Pencil clip、phase 与
  fail-closed 门禁纳入桌面回归。

## 尚未执行/后续

- 未启动设备、模拟器、虚拟机或 Hypium；ArkGraphics2D boolean 边界、非均匀 transform、Pencil texture
  clip、复杂 custom/fill、多 Group 与高速手势仍需真机集中验收。
- 当前 canonical center model 仍只表达单 component；一个 visual component 含多个 retained center run 时，
  Pencil/Dash/Dots 会拆为多个 remnant。Fixed/Variable 由 explicit custom 保持视觉，但模型层无损单实体表达
  仍受限制。
- 原版 transient partial-eraser preview/end protocol 尚未完整闭环；本阶段完成的是 durable replacement、
  rendering 与 history 语义。
- Goal 保持 active，下一阶段继续按修复总纲和边修边审结果选择高优先级原版差异。

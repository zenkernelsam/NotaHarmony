# Phase 234 修复总结：原版 Math 编辑器 Native 四态与预览

## 发现

Phase 233 完成有界文件 I/O 后，回到已经接入生产 GLMath 引擎的 Math 编辑链路继续对照原版。现有 Harmony
overlay 虽然能 durable 修改/插入 LaTeX，但仍把“非空、UTF-8 round-trip、未超过 1 MiB”直接视为可提交：

- 语法错误的 LaTeX 也会启用 Done；
- 编辑器没有显示公式 bitmap，用户只能提交后从主画布判断结果；
- 原版 Empty/Loading/Invalid/Ok 四态被压成静态 valid/invalid；
- Native 引擎初始化、连续输入、主题切换、Cancel 与页面离开时没有编辑器 preview 的异步所有权协议。

这使 Phase 149 已完成的 Native parser/draw 没有真正进入原版编辑体验，也允许静态字符串门禁与生产渲染结果分叉。

## 原版依据

- `axi.a()` 以 `lwa(Empty)` 初始化状态，并固定提供 280×96 的 preview render 尺寸。
- `w08`：空白发布 Empty；非空先发布 `nwa(Loading)`，随后通过 `s18.f(new p18(...))` 完整生成 bitmap。
- `p18`：使用 1.0 scale、主题文字色和 `s18.d()` 框内 fit；measure、尺寸或 `nativeDraw()` 任一步失败均返回
  null，失败 bitmap 会 recycle。
- Native 返回 null 时 `w08` 发布 `mwa(Invalid)`；成功 bitmap 包装为 `owa(Ok)`。
- `v08` 仅为 Ok 显示 bitmap，仅为 Invalid 显示语法提示；Done 的 enabled 严格等于当前状态是否为 Ok。
- `n07` 的 Done 提交与外层 `feature_note__math_editor_failed` 是独立失败通道，不能和语法 Invalid 合并。

## 修复

- `MathEditorOverlay`：
  - 新增 `EMPTY / LOADING / INVALID / OK` 显式状态；
  - 空白、预算/UTF-8 拒绝和 Native render 分别进入原版对应状态；
  - 新增固定 96-unit preview 区，仅 Ok 显示 `PixelMap`，仅 Invalid 显示语法提示；
  - panel 最大宽度收敛为 320，使 20-unit 双侧内边距后的内容宽度对齐原版 280 unit；
  - durable 提交失败提示保持独立；
  - Done 仅在 idle Ok 时启用。
- `NoteCanvasView`：
  - 使用生产 `OriginalMathEngine.render()` 完整绘制 280×96、1× preview；
  - 引擎初始化中保持 Loading，初始化完成后自动续验；已完成但不可用时 fail closed 为 Invalid；
  - generation、draft、visible 与 lifecycle 四重校验阻止迟到结果覆盖新状态；
  - 深浅主题变化按当前 `textPrimary` ARGB 重新绘制；
  - 替换、Cancel、提交成功和页面离开均关闭 `ImageBitmap` 并释放 `PixelMap`；
  - confirm 再次要求当前 Ok preview，防止 UI enabled 与异步结果之间的竞态绕过。
- `MathEditorOverlay.test.ets` 新增四态初值和“仅 idle Ok 可 Done”fixture；既有 `List.test.ets` 已导入并调用
  该 fixture。
- 更新本地 LaTeX 编辑和 Math consumer replay，新增原版编辑器四态专项 replay。
- 更新 ADR-0124 的过时边界，并新增 ADR-0211。

## 修改文件

- `note/src/main/ets/ui/components/MathEditorOverlay.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/test/MathEditorOverlay.test.ets`
- `docs/migration/replays/d02-local-math-latex-edit.mjs`
- `docs/migration/replays/d02-math-editing-consumer.mjs`
- `docs/migration/replays/d02-original-math-editor-four-state.mjs`
- `docs/migration/adr/ADR-0124-original-math-latex-editing.md`
- `docs/migration/adr/ADR-0211-original-math-editor-native-four-state-preview.md`
- `docs/migration/reports/修复总结-Phase234-原版Math编辑器Native四态与预览-2026-08-15.md`

## 验证

- 原版 Math 编辑器四态专项 replay：`TOTAL=29 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=221 FAILED=0`。
- 执行 `hvigorw clean --no-daemon` 后，`note@ohosTest assembleHap`：
  - `OhosTestCompileArkTS` 实际重新执行并通过；
  - `BUILD SUCCESSFUL in 12 s 571 ms`。
- clean 后 `note@default assembleHap`：`CompileArkTS`、Native Ninja 与 PackageHap 通过，
  `BUILD SUCCESSFUL in 34 s 713 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 快速连续输入合法/非法 LaTeX，确认 Loading、Invalid 与 Ok 不出现旧 preview 闪回。
- 在 Native 引擎首次初始化期间打开编辑器，确认初始化完成后自动出现预览；初始化失败时保持安全 Invalid。
- 切换深浅主题，确认旧 bitmap 被释放且公式颜色立即跟随 `textPrimary`。
- 测试分式、根号、矩阵、上下标、旋转盒、CJK、希腊文与 emoji fallback，比较原版 280×96 preview 的
  fit、裁切、baseline、透明边缘和抗锯齿。
- 在 preview 更新、Cancel、Done 和页面返回之间高频切换，观察 Native 内存与 `PixelMap` 生命周期。

## Phase 235 后续更正

Phase 234 首版把原版 `p18` 的 `scale=1` 直接解释为 raw 280×96 bitmap。Phase 235 继续追踪 `axi/r93` 后确认：
原版在进入 `p18` 前已把 280dp×96dp 乘以当前 Density，因此高密度设备必须先生成对应物理像素框，再保持
`scale=1`。该偏差已由 ADR-0212 和 Phase 235 修复；Phase 234 的四态、异步所有权与提交门禁结论不变。

# Phase 87 修复总结：原版 Shape 文字 Consumer 边界更正

日期：2026-08-11

基线：`18469fb fix(history): persist math action snapshots`

范围：Android 原版 1.0.3 Shape RichText 的可见 consumer 复核、错误待办更正

## 原版证据

- `itd.a()` 只为 note-level RichText 和 Block map `a79.I` 生成静态文本状态，没有枚举 Shape
  map `a79.G`。
- `z5c.y()` 只解析主文本或 `cie` Text Block，没有 Shape 分支。
- `kkf` 的 `m4d/n5d` 分支只把几何 Path、transform、fill path 和 border width 组装为 `lqc`；
  `fu1` 的命中也只使用几何路径与描边宽度。两者均未消费 `n5d.s`。
- Shape 仍真实持有 `m4c`，并消费 type 7-14 文本 CRDT 操作，所以 Phase 83 的入站状态修复保持正确。

## 更正

- 原版 1.0.3 的 Shape RichText 是非可见模型状态，不存在可由当前证据支持的 Shape 内文字排版、
  光标、编辑或文字命中 consumer。
- Harmony 当前 Shape renderer 只绘制几何，恰好符合原版 1.0.3；没有为追逐错误待办而复用 Text
  Block 的字体、inset 或矩形布局规则。
- ADR-0064 更正 ADR-0061/Phase 83 的未完成边界；Shape RichText 的入站回放、持久化、搜索、复制和
  包保留仍继续生效。

## 验证与边界

- 新增 `d02-shape-rich-text-consumer-boundary.mjs`，锁定主画布/缩略图的 geometry-only Shape
  consumer、TextBlock-only 文本 renderer 和 Shape CRDT 保留路径；全量桌面 replay 为
  `TOTAL=73 FAILED=0`，专项输出为 `shapeRichText=state-only-original-1.0.3`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 本阶段没有修改业务渲染代码，也没有启动模拟器、真机或 Hypium。
- Recording、Group/outbound、完整 CRDT 包与私有同步仍是独立边界；Goal 继续 active。

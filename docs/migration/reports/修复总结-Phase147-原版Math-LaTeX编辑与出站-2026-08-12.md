# Phase 147 修复总结：原版 Math LaTeX 编辑与出站

## 原版对照与问题

- 原版 `dhb/x08/v08/y22/z22/n07/u49` 明确提供单 Math 的 `Edit Math` 菜单、当前 LaTeX 预填、
  Empty/Loading/Invalid/Ok 状态、Cancel/Done 和提交失败提示。
- Harmony 此前 Phase 85/86 只完成 Math 选择、变换、剪贴板与持久历史，不能修改 LaTeX；本地编辑也没有
  type-23 field 10 writer，若直接改 snapshot 会破坏原版 CRDT authority。

## 已完成修复

- 单一 canonical Math selection 新增 `Edit Math`；原版式 modal overlay 预填 draft，Cancel 无副作用，
  非空/UTF-8/1 MiB 预算门禁控制 Done，中英文资源与失败状态齐全。
- 新增 `encodeOriginalMathLatex()`，严格编码 `td8` field 10 nullable setter 的 field-0 UTF-8 string；支持
  Undo 所需的 present empty string。
- 新增单 Math latex-only classifier。identity、元素顺序、全部非 LaTeX 字段、原始 DB snapshot 任一不一致均拒绝。
- Done 使用独立单事务提交：type-23 reducer、共享 page revision、upload-immediate op、canonical byte equality、
  search state 与 persistent-history companion 全部成功后才更新画布和 Undo 栈；失败保留 draft 和 editor。
- 普通 Undo/Redo 与 grouped history 均识别同一 mutation，不再退化为整页本地 operation。
- ADR-0124 supersede Phase 85/86 的旧 outbound-pending 边界；原生公式引擎仍明确未完成。

## 验证与边界

- 专项 replay：
  `localMathLatexEdit=original-edit-menu-prefill-validation-done|type23-field10|single-transaction|upload-immediate|canonical-reducer|persistent-history|failure-keeps-draft`。
- ArkTS fixture 已注册并通过编译，覆盖 encoder round-trip、反向 Undo、mutation 拒绝和 draft 预算。
- 全量桌面 replay 为 `TOTAL=133 FAILED=0`；`hvigorw clean` 后严格串行构建 `note@ohosTest` 与
  `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、
  真机或 Hypium。
- 当前 renderer 仍坚持不把 raw LaTeX 伪装成公式；完整 Invalid/Ok 语法判断、原生公式排版、尺寸更新与设备
  像素验收留待等价引擎阶段。Goal 保持 active。

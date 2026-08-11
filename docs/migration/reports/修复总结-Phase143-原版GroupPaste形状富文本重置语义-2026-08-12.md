# Phase 143 修复总结：原版 Group Paste 形状富文本重置语义

## 原版对照与问题

- 原版 Text 与 Shape 的复制路径并不对称。`cie.u()` 在 CREATE_BLOCK 后设置 RichText target 并调用
  `m4c.u()`；`n5d.u()` 只调用 `laj.a()` 生成 CREATE_SHAPE，完全不读取 `this.s`，也不发 type 7-14。
- `rbb.k()` 从 CREATE_SHAPE 建模时固定使用 `new m4c(null)`。因此源 Shape 即使带有隐藏 RichText，
  新副本仍是合法的空 RichText，而不是保留原值。
- Harmony 之前把 Shape RichText 当成“尚不能精确复制”的状态并拒绝整个 Group Paste。这比原版严格，
  也让一个不会影响原版副本的隐藏状态阻断正常形状复制。

## 已完成修复

- 新增单一 `originalClipboardShapeForPaste()` canonical helper：深复制 Shape 后把 `richText`、
  `characterStyleRuns` 与 `paragraphStyleRuns` 重置为空，源 clipboard 不变。
- Group Paste 预检与事务生产统一使用该 helper。带非空 RichText/样式的 Shape 现在可以正常进入
  CREATE_SHAPE、Group、NCP1 原子事务；不会伪造 INSERT_STRING 或 style operation。
- `createdShapes` 返回的是同一 reset 后对象，避免 UI/历史暂时显示源 RichText、而 reducer 持久态为空
  的内存分叉。
- 更新 Phase 136/133 replay 的旧门禁断言，新增 ADR-0120 与原版方法体专项 replay。

## 验证与边界

- 专项 replay 输出：
  `originalGroupPasteShapeRichText=n5d-create-only-rbb-empty-no-type7-14-source-immutable-copy-reset`。
- 全量桌面 replay 为 `TOTAL=129 FAILED=0`，`git diff --check` 通过。执行 `hvigorw clean` 后严格
  串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`；仅保留项目既有
  ArkTS 与未配置签名 warning。未启动模拟器、虚拟机、真机或 Hypium。
- 本阶段不删除 Shape RichText 入站模型；远端回放、包与搜索仍按 ADR-0061 保留。原版 1.0.3 又按
  ADR-0064 不显示该状态。非相似 Shape transform 仍是独立 CREATE_SHAPE 边界，Goal 保持 active。

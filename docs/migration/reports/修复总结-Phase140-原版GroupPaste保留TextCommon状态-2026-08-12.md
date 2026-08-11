# Phase 140 修复总结：原版 Group Paste 保留 Text Common 状态

## 原版对照与问题

- 原版 `baj/rl2` 的 type-22 CREATE_BLOCK 共有 21 个字段；`cie.u()` 复制 Text 时会把 corner、wrap、
  caption、Paper、resizesWidthToFitText、四边 margins 与 positionLocked 一并写入，不需要事后用
  MODIFY_BLOCK 模拟。
- Harmony 的 decoder、reducer 和数据库此前已能消费这些字段，但本地 Text encoder 只写几何并拒绝所有
  非默认 common state。更隐蔽的是模型只保存 left/top，原版独立的 bottom/right 在 snapshot、clipboard
  及第一次正文编辑 clone 中都会丢失。

## 已完成修复

- Text CREATE_BLOCK encoder 现在完整生成 common fields，并严格校验 enum、boolean、四边非负有限 margins
  与 Paper。嵌套 Paper 保留 nullable scalar presence，因此显式 `0`/`false` 不会退化为 null。
- `TextBlockElement` 增加兼容性的可选 right/bottom inset。CREATE reducer、Group Paste canonical materializer、
  RichText reducer clone 与通用 clone 均保留四边值。
- 旧 Harmony snapshot 加载时从权威 `original_block_state` 回填四边 margins；收到 MODIFY_BLOCK 时也先补齐
  遗失的 right/bottom 再做状态一致性校验，避免既有导入数据永久停留在退化状态。
- Canvas 文本测量/换行、自动宽度、编辑高度和 ArkUI overlay padding 改为独立使用 left/right/top/bottom；
  仅没有原版状态的旧本地对象继续使用对称 fallback。
- 新增 encoder fixture 覆盖所有 common state、显式零/false Paper、非法 margin/Paper；新增 ADR-0117 与
  `d02-original-group-paste-text-common-state.mjs`。

## 验证与边界

- 专项 replay 输出为
  `originalGroupPasteTextCommonState=21-field-create-paper-nullable-scalars-four-margins-legacy-recovery-asymmetric-layout`；
  全量桌面 replay 为 `TOTAL=126 FAILED=0`。
- `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、真机或 Hypium。
- 字符/段落样式仍需原版 RichText operation 序列；Shape RichText 仍是独立门禁。本阶段没有用 snapshot
  字段冒充未编码的同步 operation。

# Phase 141 修复总结：原版 Group Paste 保留 Text 样式

## 原版对照与问题

- 原版 `cie.u()` 先创建新的 Text Block，再把该 Block 设为当前 RichText 目标并调用
  `m4c.u()`。后者先插入正文、把旧字符逐 Unicode code point 映射到新 SeqId，然后发出
  type-12 `MODIFY_STYLE` 与 type-13 `MODIFY_PARAGRAPH_STYLE`。
- Harmony 此前虽然能够入站解码、持久化和渲染这些样式，但 Group Paste 的 CREATE_BLOCK
  encoder 会直接拒绝所有非空 style runs，导致带粗体、颜色、字号、链接、段落对齐等内容的
  Text 无法按原版复制。

## 已完成修复

- 新增严格 RichText style payload encoder。字符 11 类属性与段落 6 类属性分别编码为
  type-12/type-13；run 绑定本次 INSERT_STRING 的 `{timestamp, siteId, index}`，尾端严格使用
  原版 `END_OF_DOC`/省略 paragraph end 的语义。
- 索引按 Unicode code point 计算；预检拒绝空、重叠、越界 run、无属性 style、损坏 UTF-8、
  非法 enum/boolean、互斥上下标、非 canonical ARGB、不可精确往返 float32 以及 `isChecked`。
  checkbox 不冒充 type-13，继续等待独立 type-28 UpdateCheckbox 复制审计。
- Group Paste 在 CREATE_BLOCK 与 INSERT_STRING 后为每条 style 分配独立 operation identity，
  经生产 decoder/reducer 应用并写入 upload-immediate journal。所有 reducer 共用同一 revision
  batch，因此页面仍只递增一次 revision。
- canonical Text 不再由 clipboard 对象或旧 helper 拼装，而是从实际
  `page_element_snapshot` 读取；其字符/段落 runs 必须与源 runs 完全一致，否则连同 Group、
  NCP1、operation clock 和所有 journal/state 一起回滚。
- clean 主模块构建进一步暴露旧 RichText decoder 用动态 `Record<string,Object>` 写 nullable
  属性时违反 ArkTS 严格类型。现已改成覆盖全部字段的显式 presence/value 分派，未知 key 直接
  拒绝，既保留 nullable clear 语义，也消除被增量缓存掩盖的 7 个编译错误。
- 新增 ArkTS round-trip/materialization fixture、ADR-0118 与桌面 replay；同步升级 Phase 139/140
  replay，使其验证 reducer snapshot authority，而不再引用已删除的 Text materializer。

## 验证与边界

- 专项 replay 输出：
  `originalGroupPasteTextStyles=type12-type13-unicode-seqid-end-of-doc-canonical-single-revision-rollback-checkbox-gated`。
- 全量桌面 replay 为 `TOTAL=127 FAILED=0`，`git diff --check` 通过。执行 `hvigorw clean`
  后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`；仅有
  项目既有 warning。未启动模拟器、虚拟机、真机或执行 Hypium。
- 剩余边界是初始 checkbox 的 type-28 复制，以及 Shape 自有 RichText 的复制闭环；Goal 保持
  active，下一阶段继续按原版行为修复。

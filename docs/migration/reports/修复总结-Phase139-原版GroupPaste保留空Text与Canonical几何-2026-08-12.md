# Phase 139 修复总结：原版 Group Paste 保留空 Text 与 Canonical 几何

## 原版对照与问题

- 原版 type-22 CREATE_BLOCK 不携带正文，空 Text 只需要 Block；正文由独立 RichText CRDT operation 写入。
  `f46.a()` 明确拒绝空 INSERT_STRING，因此不能为通过门禁而伪造 type-8 空字符串。
- Harmony Group Paste 此前直接拒绝空 Text；非空 Text 又把高精度 clipboard preview 写回 snapshot/UI，
  可能与 CREATE_BLOCK 已保存的 float32 origin/rotation/scale/size 基线分叉。

## 已完成修复

- preflight 现在允许空 Text 并只校验 CREATE_BLOCK；非空和纯空白 Text 才继续校验原版 INSERT_STRING。
- 事务始终创建 Text Block；仅当 `richText.length > 0` 时分配第二个 identity、应用 type-8 并写
  upload-immediate journal。空 Text 直接进入共享 revision flush、CREATE_GROUP 与 NCP1，整个动作仍原子回滚。
- 所有普通 Text 的返回对象都从 decoded CREATE_BLOCK 重建：`textOrigin` 归一为零，transform/size 使用实际
  float32 wire 值，正文与新 originalCreate metadata 保留，使 state、snapshot、NCP1 和 UI 使用同一几何。
- 新增 ADR-0116、`d02-original-group-paste-empty-text.mjs`，更新旧 transaction replay，并扩展 Group plan
  ArkTS fixture 覆盖空 Text、Image 与 Math 的混合成员。

## 验证与边界

- 专项 replay 输出为
  `originalGroupPasteEmptyText=create-block-without-empty-insert-single-revision-canonical-group-ncp1-rollback`；
  全量桌面 replay 为 `TOTAL=125 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、真机或 Hypium。
- Text common Block 状态、字符/段落样式和 Shape RichText 仍需原版 operation 序列，继续明确门禁，不用
  compatibility snapshot 冒充原版同步数据。

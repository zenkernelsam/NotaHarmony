# Phase 142 修复总结：原版 Group Paste 复选框重置语义

## 原版对照与问题

- Phase 141 暂时拒绝任何含 `isChecked` 的 Text，以免把 checkbox 错塞进 type-13 或凭空发
  type-28。继续审计原版后确认，这个门禁比原版更严格：`cie.u()` 只调用一次 `m4c.u()`，而完整
  copy 方法只映射字符和 style spans，从不读取独立 checkbox map `this.m`。
- `m4c.u()` 中的 `n4c.o()/d3c` 实际是 Link；`he8` 又明确声明 paragraph `isChecked` 已废弃、
  应使用 UpdateCheckbox。复制路径没有 UpdateCheckbox，因此原版会保留 CHECK_BOX decorator，
  但新副本没有 checked register，显示为未勾选。

## 已完成修复

- Group Paste 现允许包含 `isChecked` 的 Text，编码 type-13 前仅复制 6 类合法段落属性并省略
  checkbox state；没有伪造 type-28，也没有使用废弃 paragraph 字段。
- 去掉 `isChecked` 后会合并相邻且其余样式相同的 runs。这样源文档中仅因各字符 checked 值不同
  而拆开的段落，在副本中恢复为原版连续 decorator span。
- reducer canonical 校验同步改为对比“去 checkbox + 合并”后的预期；源 clipboard 保持不变，
  新副本按原版统一未勾选。损坏的非 boolean checkbox 值仍在预检拒绝。
- 新增 ADR-0119、原版方法体静态 replay 与 ArkTS materialization fixture，并升级 Phase 141
  replay 的 checkbox 边界说明。

## 验证与边界

- 专项 replay 输出：
  `originalGroupPasteCheckboxReset=m4c-copy-omits-checkbox-map-no-type28-decorator-kept-adjacent-runs-coalesced-unchecked`。
- 最终全量桌面 replay 为 `TOTAL=128 FAILED=0`，`git diff --check` 通过。执行 `hvigorw clean`
  后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`；仅保留
  项目既有 ArkTS 与未配置签名 warning。未启动模拟器、虚拟机、真机或 Hypium。
- 本阶段不等于实现本地 checkbox 点击出站；用户主动切换仍需独立 type-28 writer/UI 审计。
  Shape RichText 复制也继续作为后续边界，Goal 保持 active。

# ADR-0761 — 1.0.1→1.0.3 资源/manifest 全量差(谱系补全)

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0741(1.0.x 谱系)、ADR-0747(字体)、Phase 797

## 背景

Phase 797 仅以 strings.xml 键差登记了 1.0.1→1.0.3 行内差。
resources 全树(含 META-INF/font/manifest)未做同粒度对比。

## 取证结论

- 文件级 1,166→1,174:+19/−11。
- 新增层：Singular 归因 SDK 首次随包(kotlin_module)、
  Play AppSet、5 个品牌字重(GT America Mono Bold、GT Flaire
  Extra、Proxima Soft Medium、Untitled Serif×2)、check 图标、
  11 个 services 混淆名重排(对应 11 个移除)。
- 同路径内容变化 9 项：manifest、版本信息、baseline prof、
  strings/plurals/public、RemoteConfig、ads-identifier props。
- strings +33/−12：账户删除全生命周期族 + 登出同步状态族 +
  付费墙重组(797 结论的更完整形态)。
- manifest：FileProvider→ExportFileProvider、FB/IG queries、
  AD_ID + Singular preinstall 权限、ADID collection meta-data。

## 决策

1. 1.0.1→1.0.3 登记为"归因栈上车 + 品牌字体补全 + 账户生命周期
   加固 + 导出 Provider 定制"的增量版本，无功能下线。
2. Singular/AD_ID/preinstall 权限属归因/GMS 面,Harmony 无对应
   物,fail-closed 登记(与 GMS/后端边界一致)。
3. FB/IG queries 为分享目标探测,Harmony 分享面不依赖包探测,
   登记差异即可。

## 后果

- 三版谱系(1.0.1→1.0.3→1.4.2)的资源层证据链闭合：
  797(strings)→ 本 ADR(全树+manifest)→ 后续版本差各阶段。
- Replay `d02-101-103-resource-diff.mjs` 15/15 钉住。

# ADR-0760 — locale split 翻译覆盖矩阵与 Harmony 本地化广度

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0739(XAPK split/l10n)、Phase 795

## 背景

Phase 795 登记了 1.4.2 的 17 个 locale split 存在，但未量化每个
语言的实际翻译深度 —— "声明支持"与"真实翻译"可能不同。

## 取证结论

- 15 个 locale(ar/de/es/fr/hi/in/it/ja/ko/pt/ru/th/tr/vi/zh)的
  `resources.arsc` 字符串池各含 ~1,830-1,950 条 —— 与基准
  strings(~1,400 键 + 复数/厂商扩展)规模匹配，为全量翻译。
- `config.my`(缅甸语)仅 93 条 —— 桩级/挂名 locale。
- `config.en`/`config.xxhdpi` 为基准/密度标记(141/48 条)。
- zh split = 应用 zh-Hans(笔记/文件夹/录音简体)+ 厂商
  zh-Hant(GMS/Samsung 文案)并存。

## 决策

1. **本地化广度差距登记**:Harmony 当前为 en base + zh_CN 两档;
   原版全量本地化广度为 15 语言 + 1 桩。属未实现的本地化扩展，
   非行为缺陷 —— 日后扩展语言档时以本矩阵为原版基线。
2. **zh-Hans 确认**:原版 zh split 的应用文案为简体中文，与
   Harmony `zh_CN` 档位同语域，既有 zh_CN 文案语域选择正确。
3. `config.my` 桩级状态登记为原版的商店声明与实际翻译差距。

## 后果

- locale 面闭合：存在性(795)+ 覆盖深度(本 ADR)两级证据齐备。
- Replay `d02-locale-coverage.mjs` 6/6 钉住覆盖矩阵与 zh 双语态。

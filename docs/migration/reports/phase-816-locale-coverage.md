# Phase 816 — locale split 翻译覆盖矩阵(中文报告)

## 本阶段结论

解析 17 个 locale split 的 `resources.arsc` 字符串池，量化原版
本地化深度:**15 个语言全量翻译(~1,830-1,950 条),缅甸语
(my)为 93 条桩级,en/xxhdpi 为标记 split**。

## 覆盖矩阵摘要

- 全量(15):ar de es fr hi in it ja ko pt ru th tr vi zh
- 桩级:my(93 条，商店声明与翻译深度不符)
- 标记:en(141)、xxhdpi(48)

## zh split 细查

- 1,936 条字符串，~96% CJK。
- 应用文案为**简体中文**(笔记/文件夹/录音简体形；删除组合
  复数翻译完整，如 "也将删除 %2$d 个文件夹和 %3$d 条笔记")。
- 厂商文案(Google Play 服务/Samsung IAP/导航)保留繁体
  `服務`/`裝置`/`開啟` —— 应用 zh-Hans + 厂商 zh-Hant 并存。

## Harmony 侧

Harmony 当前 en base + zh_CN 两档。原版本地化广度(15 全量+1 桩)
登记为未实现的本地化扩展面(非缺陷);zh_CN 语域选择经核对与
原版 zh split 一致(同为简体)。

## 验证

- Replay:`d02-locale-coverage.mjs` 6/6;全量 689/689 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-816-locale-coverage.md`
- `docs/migration/replays/d02-locale-coverage.mjs`
- `docs/migration/adr/ADR-0760-locale-coverage.md`
- 本报告

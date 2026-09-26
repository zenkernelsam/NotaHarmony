# ADR-0751：笔色板包面移植（spen_* 调色板库）

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-807-pen-palettes.md`
- Replay：`docs/migration/replays/d02-pen-palettes.mjs`

## 决定

将原版 `spen_*` 色板面移植进 Harmony：新增 `PenPalettes.ets` 数据层
（3 组自适应色条 + 23 主题包 + 21 自适应变体），`ColorPicker` 增加
Swiper 分页色板库区；保留既有 12 预设快取条不变。

## 依据

- 原版 arrays.xml 的 70 个 `spen_*` 数组两版逐字节一致——纯资源面，
  无版本演进风险。
- Harmony 原 12 预设与原版 39/65/65 色条 + 23×8 包差距明显，
  属可移植本地数据缺口（色值全部随包内资源发放，无后端）。
- 深色主题取 adaptive 变体复现原版自适应语义（如 252525→dadada
  反色保障深色纸面/主题可读性）。
- a11y 沿用原版 `ui_tools__color_hex` 格式（"Color #%1$s"）作为
  未命名色通用播报。

## 影响

- 功能：色板库可浏览/可点选，笔色选择面显著扩齐。
- 呈现差异：原版包承载容器（Compose 混淆不可完全恢复）以 Swiper
  分页等价实现——登记为呈现差异而非语义差异。
- 数据层 `PenPalettes.ets` 同时把三组默认色条入库，为后续
  "默认色条随纸色/主题自适应"留好数据基座。

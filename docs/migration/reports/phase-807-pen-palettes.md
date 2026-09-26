# Phase 807 报告：笔色板包面（spen_*）移植

日期：2026-09-23
Phase 类型：数据移植 + UI 扩展（实改代码）

## 摘要

发现原版 `arrays.xml` 的 `spen_*` 色板面（两版逐字节一致）：3 组
自适应默认色条（标准 39 / 浅 65 / 深 65 色）+ 23 个主题色板包
×8 色 + 21 个深色自适应变体 + 196 个命名色 a11y。Harmony 原为
固定 12 预设，存在明确移植缺口。

## 实现

- 新建 `note/src/main/ets/data/PenPalettes.ets`：完整色板数据层。
- `ColorPicker.ets` 新增色板库区：`Swiper` 分页承载 23 个包
  （4×2 色点页），深色主题自动取 adaptive 变体。
- a11y：色点沿用原版 `ui_tools__color_hex`（"Color #%1$s"）格式
  播报色号；新增区段标题 `pen_string_palette_library`（EN+zh_CN）。

## 差异登记

原版色板库的具体 Compose 承载容器经混淆不可完整恢复，Harmony 以
Swiper 分页实现语义等价的可浏览包集合；默认色条入库备用（后续
随纸色/主题自适应接入）。

## 验证

- `d02-pen-palettes.mjs`：6/6 green
- 全量 Desktop Replay 与双 HAP：见提交（default 构建已含本次
  ArkTS 改动编译通过）

## 产物

- 数据：`note/src/main/ets/data/PenPalettes.ets`
- UI：`note/src/main/ets/ui/components/ColorPicker.ets`
- 资源：`base`/`zh_CN` `element/string.json`（+2 keys each）
- 证据：`docs/migration/evidence/phase-807-pen-palettes.md`
- Replay：`docs/migration/replays/d02-pen-palettes.mjs`
- ADR：`docs/migration/adr/ADR-0751-pen-palettes.md`

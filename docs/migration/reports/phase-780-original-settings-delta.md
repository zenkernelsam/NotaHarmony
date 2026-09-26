# Phase 780 — 原版 1.4.2 设置面增量登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-780-original-settings-delta.md`
ADR：`ADR-0724-original-settings-delta.md`
Replay：`d02-original-settings-delta.mjs`（14/14）

## 本阶段做了什么

对 `feature_settings__*` 键族做 1.0.3↔1.4.2 全差集：
+60 新增 / −14 移除，并定位代码佐证。

## 发现

- 新增六族：打字默认（字体/字号/行距/网格/拼写）、
  手势（tap-anywhere/双指）、笔记标题模板、TTS 速度
  （rcj 滑杆）、社媒页脚五链、newsletter 营销。
- 移除十四键全属账号登出段与旧主题键——1.4.2 设置
  重构（移入资料页/改键），非功能删除。
- Harmony 无打字默认/标题模板/手势/TTS 对应面。

## 分类

- 打字默认 + 标题模板 + 手势：版本差·本地候选。
- TTS 速度：系统 TTS 等价物评审。
- newsletter/restore：后端边界；passkey/calendar 已登记。

## 验收

- Replay 14/14 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。

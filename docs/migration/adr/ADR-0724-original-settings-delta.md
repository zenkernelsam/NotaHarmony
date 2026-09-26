# ADR-0724 — 原版 1.4.2 设置面增量登记

日期：2026-09-29
状态：已登记（版本差·本地候选混合后端边界；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-780-original-settings-delta.md`
Replay：`docs/migration/replays/d02-original-settings-delta.mjs`

## 背景

1.4.2 设置面 +60/−14：新增打字默认（字体/字号/行距/网格）、
笔记标题模板（前后缀+日期时间）、tap-anywhere、双指点按、
拼写检查、TTS 速度滑杆、社媒页脚、newsletter 营销；
移除 logout_*/sign_out/dark_theme 旧键（账号段重构）。

## 决策

1. **打字默认 + 标题模板 + 手势开关**：版本差·本地候选——
   纯偏好存储驱动编辑器默认行为，可移植。
2. **TTS 速度**：需 HarmonyOS 系统 TTS 等价物评审。
3. **newsletter/restore/passkey/calendar**：后端或已登记族。
4. logout/theme 移除记为原版重构，非差异功能。
5. 本阶段不实现。

## 后果

- 设置面增量六族 + 移除族全部钉入 Replay。
- 本地候选清单继续累积至 T-042。

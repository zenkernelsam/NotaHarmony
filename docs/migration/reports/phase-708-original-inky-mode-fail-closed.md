# Phase 708：原版 Inky 动画吉祥物模式 fail-closed 登记

`ac4` 旗标注册表系统审计继续：`INKY_MODE`（`ac4.p0`，序号 31）
为尚未完整登记的门控面。

## 原版证据链

- `w16.java:20`：`lc4.a(ac4.p0) && !z` → `inkyModeAvailable`；
  `z16` 接入状态流 → 工具栏状态 `t9f` 双字段
  （`inkyModeAvailable`/`inkyModeEnabled`）。
- 选项菜单 `feature_note__options_menu_inky`（"Inky"，`z22:354`）
  → `l26`/`k26` `inky_mode_enabled` datastore 偏好（默认关）。
- `h26.java`：Inky 悬浮层 = **Rive 动画**——
  `e5c.b(RiveFileSource.RawRes.from(R.raw.feature_note_inky__
  inky_2026_v32,…))` 加载 `res/raw` 内 304 KB `.riv` 资产 +
  `inkyAlpha` 渐变过渡（`h26:294/428/818/1034`）。

## 决定

- Rive 为第三方动画运行时（`.riv` 二进制格式）；Harmony 无
  等价运行时，自行实现 Rive 解码器超出本迁移范围——按
  Klipy/`AnimatedImageDrawable` 同族判据登记结构性 fail-closed
  （`ADR-0656`）。
- 前置审计（`ADR-0544` 编辑器 ⋮ 菜单）已将 Inky 菜单项记为
  "无对应面"，`NotePage.ets` 注释在案；本阶段补全
  旗标→状态→Rive 呈现完整证据链并独立登记。
- 纯 UI 吉祥物层，无笔记数据/ops 面——无数据登记需求。
- Harmony 呈现等价旗标关闭态：无 Inky 入口/开关/悬浮层。

## 验证

- `d05-original-inky-mode-fail-closed.mjs`（15 断言：原版
  旗标链/datastore/菜单串/Rive 资产存在性/Harmony 无实现
  标识符/既有注释豁免/ADR+证据存在）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。

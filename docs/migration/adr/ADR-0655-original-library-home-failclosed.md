# ADR-0655 「LIBRARY_HOME」首页分区 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：706

> **更正（2026-09-25，ADR-0691）**：本文“旗标关闭态=Harmony
> 现状”的判定有误——`androidLibraryHome` 打包默认 `true` 且该
> 旗标为 PRODUCTION 级直读远程配置值，1.0.3 默认显示 Home
> 分区。缺口改由 ADR-0691 登记为延迟移植缺口；其中
> `home_study_up_next` 的 Learn 后端依赖维持 ADR-0652 原判。
- 接续：ADR-0652（Learn/AI 面 fail-closed）、ADR-0518+（library
  表面既有登记）
- 证据：`docs/migration/evidence/original-library-home-jadx-2026-09-24.md`

## 背景

原版 `ac4.F0`（`LIBRARY_HOME`，序号 47）远程旗标控制新版
Library "Home" 分区：`ajh.java:335` 处 `lc4.a(ac4.F0)` 为真时向
导航列表插入 `feature_library__home` 条目（`tnc.a` 图标），否则
跳过该区（else 分支空渲染）。`va7:30`、`wa7:118` 同门控。

旗标开启的 Home 区由 `ksh` 组合族构成：

- `ksh.d`："Let's get started" 双 CTA 卡——`home_record_lecture`
  （Record a lecture）与 `home_take_notes`（Take notes /
  starter 变体 "Take %d notes for free"）；
- `ksh:287`：`home_favorite_notes` 区；
- `ksh:878`：`home_study_up_next` 学习待办（Learn 面，
  ADR-0652 已登记 fail-closed）；
- `ksh:1125`：`home_recent_notes` 区；
- `oi5`/`pi5`/`hs4`/`haj`/`aj5`：卡片网格行渲染。

Harmony 现状：经典 Library（Recent/Favorite/Shared/文件夹
导航 + FAB 创建菜单），**无 Home 分区**——即旗标关闭态。

## 决定

1. **不实现 LIBRARY_HOME 首页分区**：等价于 `ac4.F0` 评估为
   false 的原版经典库体验——导航列表无 Home 条目、无首页
   onboarding 卡。
2. **功能等价已覆盖**：
   - Record a lecture → FAB "Record audio"（`createAndRecord`）；
   - Take notes → FAB "New note"（`createAndOpen`）；
   - Recent/Favorite 区 → 现有 Recent/Favorite 库节；
   - Study up next → Learn 面（ADR-0652，结构性 fail-closed）。
3. **旗标关闭态非缺陷**：原版旗标域本身即把该面做远程灰度；
   Harmony 呈现与旗标关闭的 1.0.3 完全一致。

## 后果

- 原版旗标关闭用户体验 = Harmony 体验；
- 若将来需要旗标开启等价，重开本 ADR 可逐项补 Home 区
  （CTA 卡 + 双最近区 + Learn 待办——Learn 仍受 ADR-0652 约束）。

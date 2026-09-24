# Phase 706：原版 LIBRARY_HOME 首页分区 fail-closed 登记

继续 `feature_library__*` 扫描：`home_*` 一组字符串指向未登记面
——新版 Library Home 分区。JADX 审计确认其为 `ac4.F0`
（LIBRARY_HOME，#47）远程旗标灰度面，登记 fail-closed
（ADR-0655）。

## 原版证据

- `ajh:335`：`lc4.a(ac4.F0)` 为真才向导航插入 Home 条目
  （else 空渲染）；`va7:30`/`wa7:118` 同门控。
- Home 区（ksh 族）：
  - `ksh.d` "Let's get started" 双 CTA 卡（Record a lecture /
    Take notes + starter 计数变体）；
  - `home_favorite_notes`/`home_recent_notes` 双区；
  - `home_study_up_next` Learn 待办（ADR-0652 已登记）；
  - `oi5`/`pi5`/`hs4`/`haj` 卡片网格；`ht8.RECORD_LECTURE` 分析枚举。

## Harmony 现状

经典库（Recent/Favorite/Shared/文件夹 + FAB 创建菜单），无
Home 分区 = 旗标关闭态。功能等价已覆盖：

- Record a lecture → FAB "Record audio"（createAndRecord）；
- Take notes → FAB "New note"（createAndOpen）；
- Recent/Favorite → 现有库节（empty-states fixture 覆盖）；
- Study up next → Learn 面（ADR-0652）。

## 产物

- `docs/migration/adr/ADR-0655-original-library-home-failclosed.md`
- `docs/migration/evidence/original-library-home-jadx-2026-09-24.md`
- `docs/migration/replays/d05-original-library-home-fail-closed.mjs`
  （9 断言：旗标门控/Home 组成/Harmony 关闭态等价）

## 验证

- 专项 9/9；全套件重跑通过后记录于修复总纲；双 HAP 0 错误。

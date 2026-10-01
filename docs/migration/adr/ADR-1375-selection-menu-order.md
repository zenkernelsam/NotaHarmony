# ADR-1375 — 元素选择菜单按 urf 装配序对齐 + SEND_* f() 门控

## 状态

已接受（Phase 1440）。

## 背景

原版 `urf` 装配器（urf.java:260-470）把 `wqf` 枚举行分两条列表：
主行 `arrayList` 与 MORE 子菜单 `arrayList2`（`xqf` 二元组，a0=MORE
行尾箭头触发 `msc.b` 双行 `showSubmenu`）。Harmony 早前以单行
bindMenu 平铺整个菜单（ADR-0645 登记的 MORE 平铺适配），但行序按
当时理解的 dsc 枚举序排列，与 urf 真实发射序多处错位。

## 原版证据

主行发射序：
`[CROP](l97 图像 lsf) [EDIT_MATH](cv9 数学 lsf) [STYLE](ink 可样式化
扫描 || vvh&&h35.S0 调试旗) COPY CUT DUPLICATE [GROUP|UNGROUP](jsf→UN；
isf 单组→UN/≥2→GROUP/其余→无行) [LOCK|UNLOCK](h45.b(h35.I))
[DESELECT](isf) DELETE [MORE]`

子菜单发射序：
`[FLIP_H FLIP_V](l97) [CONVERT_TO_MATH](全ink&&zB) [CONVERT_TO_TEXT]
(全ink&&可转) [SAVE_AS_STICKER](h35.z0 InternalUserOnly) [SEND_TO_FRONT
SEND_TO_BACK SEND_FORWARD SEND_BACKWARD](!msfVar.f().isEmpty())`

`msf.f()`：lsf=单实体集、jsf=组成员叶子集、isf=`q=g−p`（选中叶子
减已选组成员并集，`y2g.d0`/`isf.java:52-61`）。纯组绘制选区 `q` 空
→ SEND_* 四行不装配。

`h35.I` = POSITION_LOCKED：`td5` 灰度旗（远端键
`androidPositionLocked`，不在 defaults XML → 生产缺省 false；
live-since 2026-05-29）。同一旗门控 `guf:1175`/`m52:38`/`ofk:970`/
`ot2:98`/`xnm:116` 整条锁链。

## 决定

1. `buildSelectionMenu` 重排为 urf 平铺序（MORE 子菜单按原序贴至
   行尾；CONVERT_*/STICKER/FIT_TO_PAGE 维持 ADR-0645/1364 fail-closed
   缺省）。PASTE 维持 DUPLICATE 后剪贴板簇位（t6b 浮动条适配，再登记）。
2. 新增 `canReorder` 门控 SEND_* 四行：`isf 型 && selectedGroupIds>0
   && 全部选中叶子 ∈ 已选组成员并集` → 隐藏（isf.q 空等价）。
   `jsf` 组点选（supportsDeselectMode=false）与 lsf 恒显示。
3. LOCK 行保留（td5 灰度旗本地实现=已移植+旗门登记，同 textOnly
   判例），注释补记 `androidPositionLocked` 远端键。
4. isf 单成员退化分支：`urf` 反编译尾部 `wqfVar3=null` 折叠点存在
   歧义（单非组成员可能挂 UNGROUP 死行）；`dhb` case5 对该路径
   为静默 no-op 死操作——不移植疑似死行，Harmony 维持无行。

## 后果

- 菜单顺序、SEND_* 行存现性与原版逐位对齐。
- LOCK 行为语义不变（旗门仅登记）；DESELECT isf 门（P1439）不变。
- 选区菜单行序此后以 urf 发射序为唯一事实源。

## 验证

- `d02-selection-menu-urf-order.mjs`：25 项断言（17 项相对序 +
  门控/旗注/文档闭环）。
- 全量基线与双 HAP 构建见 Phase 1440 report。

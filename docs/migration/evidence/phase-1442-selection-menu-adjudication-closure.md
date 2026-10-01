# Phase 1442 — wqf/urf 选择菜单轴终局裁决（证据）

## 枚举全映射（wqf.java:30-78）

| 字段 | 名 | ordinal | 装配位置 |
|------|-----|---------|----------|
| F | STYLE | 0 | 主行（ink 扫描/vvh+S0 调试旗） |
| G | COPY | 1 | 主行无条件 |
| H | CUT | 2 | 主行无条件 |
| I | DUPLICATE | 3 | 主行无条件 |
| J | GROUP | 4 | isf ≥2 实体 |
| K | UNGROUP | 5 | jsf / isf 纯单组（折行歧义登记 ADR-1375） |
| L | SEND_FORWARD | 6 | 子菜单 f() 非空 |
| M | SEND_BACKWARD | 7 | 同上 |
| N | SEND_TO_FRONT | 8 | 同上 |
| O | SEND_TO_BACK | 9 | 同上 |
| P | DELETE | 10 | 主行无条件 |
| Q | CONVERT_TO_MATH | 11 | 子菜单：全 mn7 + h45.b(h35.e0) |
| R | CONVERT_TO_TEXT | 12 | 子菜单：全 mn7 + 任一 oim.b(k!=HIGHLIGHTER) |
| S | EDIT_MATH | 13 | 主行 lsf+cv9（P1441） |
| T | SAVE_AS_STICKER | 14 | 子菜单：h45.b(h35.z0) |
| U | CROP | 15 | 主行 lsf+l97（P1441） |
| — | **FIT_TO_PAGE** | 16 | **wqfVar17 从未赋静态字段——死枚举** |
| V | FLIP_HORIZONTALLY | 17 | 子菜单 lsf+l97 |
| W | FLIP_VERTICALLY | 18 | 同上 |
| X | LOCK | 19 | 旗门 h35.I + lsf/cjm.g 或 A()=FALSE |
| Y | UNLOCK | 20 | 旗门 + A()=TRUE 或 z 支单行 |
| Z | DESELECT | 21 | 主行 isf（P1439） |
| a0 | MORE | 22 | 主行尾（子菜单非空） |

## 本 Phase 四项裁决明细

### CONVERT_TO_MATH（Q）
`urf` 装配：`!set6.isEmpty() && arrayList3.size()==set5.size() && zB`——
全部选中成员经 `zq.c0` 解析为 `mn7`（笔画实体），且 `zB=h45.b(h35.e0)`。
`h35.e0` = `MATH_HANDWRITING_RECOGNITION` =
`td5(cje.c="androidMathHandwritingRecognition", 2026-09-02)`；
defaults XML 中该键 `<value>false` → 生产旗关。
**双重 fail-closed**：旗缺省关闭 + 识别引擎为 MyScript iink 私有。

### CONVERT_TO_TEXT（R）
行门无旗标：全 mn7 + 任一 `oim.b(mn7)=k!=uo7.HIGHLIGHTER`。
但 `d9c` 分发为 `(bz5).invoke(y1d)` → 转换执行链入 iink 手写识别。
**fail-closed**：行缺省即正确——出行而无引擎属坏路径。

### SAVE_AS_STICKER（T）
`h45.b(h35.z0)`；`h35.z0` = `STICKERS` = `rd5(null)` InternalUserOnly
（rd5 生产恒 false，非 RemoteConfig）→ **生产恒不可达**。

### FIT_TO_PAGE
`wqfVar17` 构造后**未赋静态字段**（wqf.java:63-64 无赋值行），
`b0` 值数组含之但无任何 `urf.add` 路径可达；`m36 case16` 为死渲染支；
1.0.3 `dhb` case15 亦 `throw NotImplementedError` → **原版即死项**。

## Harmony 状态

`SelectionMenuAction` 20 枚枚举不含四项；`NoteCanvasView` 分发无残留；
urf 终局注释已登记于 `SelectionOverlay.ets:175-184`。
**wqf/urf 菜单轴全部 23 项至此裁决完毕**（19 项已移植/合并适配 +
4 项本 Phase fail-closed/死项）。

## 验证

`d02-selection-menu-adjudication-closure.mjs`：14/14 绿。

# Phase 1440 — 选择菜单 urf 装配序 + SEND_* f() 门控（证据）

## 原版证据（decompiled_1.4.2）

### `wqf` 枚举（wqf.java:32-76，23 项 + FIT_TO_PAGE 死枚举）

| 字段 | 名 | ordinal |
|------|----|---------|
| F | STYLE | 0 |
| G | COPY | 1 |
| H | CUT | 2 |
| I | DUPLICATE | 3 |
| J | GROUP | 4 |
| K | UNGROUP | 5 |
| L | SEND_FORWARD | 6 |
| M | SEND_BACKWARD | 7 |
| N | SEND_TO_FRONT | 8 |
| O | SEND_TO_BACK | 9 |
| P | DELETE | 10 |
| Q | CONVERT_TO_MATH | 11 |
| R | CONVERT_TO_TEXT | 12 |
| S | EDIT_MATH | 13 |
| T | SAVE_AS_STICKER | 14 |
| (var17) | FIT_TO_PAGE | 16（静态字段未赋值=死枚举；dhb case15 NotImplementedError 上游死项） |
| V | FLIP_HORIZONTALLY | 17 |
| W | FLIP_VERTICALLY | 18 |
| X | LOCK | 19 |
| Y | UNLOCK | 20 |
| Z | DESELECT | 21 |
| a0 | MORE | 22 |

### `urf` 装配器（urf.java:260-470）——主行 `arrayList` 发射序

```
[CROP]      if (hv6VarP1 instanceof l97)          // lsf 单元素为图像
[EDIT_MATH] if (hv6VarP1 instanceof cv9)          // lsf 单元素为数学
[STYLE]     !vvh 且选中集含可样式化 ink 成员（zq.c0/f5g 扫描）
            或 vvh 且 h45.b(h35.S0)                // TEXT_BOX_PAPER qd5 调试门
COPY / CUT / DUPLICATE                            // 无条件
[UNGROUP|GROUP] jsf→K(UNGROUP)；isf: m.size==1&&q 空→UNGROUP，
                q+m≥2→GROUP；lsf/hsf→null 无行
[LOCK|UNLOCK] if (h45.b(h35.I))                   // ← POSITION_LOCKED td5 旗
              lsf+可锁实体→LOCK；否则 A(msfVar) TRUE→UNLOCK / FALSE→LOCK
[DESELECT]  if (msfVar instanceof isf)            // P1439 已对齐
DELETE                                            // 无条件，主行尾
[MORE]      if (!arrayList2.isEmpty())            // 子菜单箭头
```

### `urf` 子菜单 `arrayList2` 发射序

```
[FLIP_H] [FLIP_V]        if (z6) 单图像 lsf
[CONVERT_TO_MATH]        全 ink 选区 && zB
[CONVERT_TO_TEXT]        全 ink 且存在 oim.b 可转成员
[SAVE_AS_STICKER]        h45.b(h35.z0)（STICKERS rd5 InternalUserOnly）
[SEND_TO_FRONT] [SEND_TO_BACK] [SEND_FORWARD] [SEND_BACKWARD]
                         if (!msfVar.f().isEmpty())
```

### `msf.f()`（z-orderable 集）逐类型

- `lsf.f()` = `tee.T(a)` = 单实体集（恒非空）
- `jsf.f()` = `this.i` = 组内成员叶子（恒非空）
- `isf.f()` = `this.q` = `g − p`（`y2g.d0` set-minus：`g`=选中叶子全集，
  `p`=已选组 `m` 各 `tof.c()` 成员并集）——**纯组绘制选区 q 空 → SEND_*
  四行不产**

### `h35.I` = POSITION_LOCKED 旗标语义

- `h35.java:105`：`new h35("POSITION_LOCKED", 1, new td5(wje.c, LocalDate
  .of(2026,5,29)), null)`；`wje.c` = `new wje("androidPositionLocked")`。
- `h45.c` 对 `td5`：生产构建 → `the.g(remoteKey)==TRUE` 否则 `return
  false`；远端键 `androidPositionLocked` **不在**
  `core_remoteconfig__remote_config_defaults.xml`（58 键全表核对）→
  生产缺省 false。
- 其它 `h45.b(h35.I)` 消费点：`guf.java:1175`、`m52.java:38`、
  `ofk.java:970`（实体构造 positionLocked 写位）、`ot2.java:98`、
  `xnm.java:116`——整条锁特性链同旗门控。
- 判例：`td5`+live-since 日期=灰度推送旗（与 androidTextOnlyMode 同
  类）；本地实现保留接线 = "已移植+旗门登记"（P1438 textOnly 先例）。

## Harmony 缺口（修复前）

1. 行序不符：CROP/EDIT_MATH 殿后（原版领衔）、DELETE 居中（原版
   MORE 前主行尾）、SEND_* 序 FWD,BWD,TO_FRONT,TO_BACK（原版
   TO_FRONT,TO_BACK,FWD,BWD）、LOCK/DESELECT/DELETE 相对位次错位。
2. SEND_* 四行无条件装配——纯组绘制选区（isf.q 空）也显示。

## Harmony 实现

- `SelectionOverlay.buildSelectionMenu` 重排为 urf 平铺序：
  `[CROP][EDIT_MATH][STYLE] COPY CUT DUPLICATE [PASTE*] [GROUP|UNGROUP]
   [LOCK|UNLOCK] [DESELECT] DELETE [FLIP_H FLIP_V] [TO_FRONT TO_BACK
   FORWARD BACKWARD]`（*PASTE=已登记适配，原版为 t6b 浮动条）。
- 新 `@Prop canReorder` 门控 SEND_* 块；`@State selectionCanReorder`
  镜像 = `!(isf型 && groupIds>0 && 所有选中叶子∈已选组成员)`。
- LOCK 门注释补记 h35.I 旗门；DESELECT isf 门（P1439）保留。

## 判定

- 行序 + SEND_* f() 门控已对齐；CONVERT_*/STICKER/FIT_TO_PAGE/MORE
  仍按 ADR-0645/1364/1371 fail-closed 缺省。
- GROUP/UNGROUP 互斥门控此前已裁决（dhb case5/gtc/ftc 死路径注释），
  isf 单成员退化分支的反编译折行歧义（`wqfVar3=null` 折叠点）在
  ADR-1375 登记——不移植疑似死行。

## 验证

- Replay `d02-selection-menu-urf-order.mjs`：25/25 green。
- 全量 Desktop Replay / 双 HAP 构建：见 report。

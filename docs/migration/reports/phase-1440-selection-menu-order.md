# Phase 1440 — 选择菜单 urf 装配序对齐 + SEND_* f() 门控

## 原版硬证据（decompiled_1.4.2）

- `wqf.java` 23 枚枚举全映射 + `urf.java:260-470` 装配器双列表发射序。
- 主行：`[CROP](l97 图像 lsf) [EDIT_MATH](cv9 数学 lsf) [STYLE](ink
  可样式化扫描||vvh&&h35.S0 调试旗) COPY CUT DUPLICATE [GROUP|UNGROUP]
  [LOCK|UNLOCK](h45.b(h35.I) td5 旗) [DESELECT](isf 专属) DELETE [MORE]`。
- 子菜单：`[FLIP_H FLIP_V](l97) [CONVERT_TO_MATH/TEXT](全 ink 系门)
  [SAVE_AS_STICKER](h35.z0 rd5) [SEND_TO_FRONT SEND_TO_BACK
  SEND_FORWARD SEND_BACKWARD](!f().isEmpty())`。
- `msf.f()`：isf=`q=g−p`（`y2g.d0` set-minus；纯组绘制选区 q 空）；
  jsf=`i`（组成员叶子）、lsf=单实体集——后两者恒非空。
- `h35.I`=POSITION_LOCKED=`td5(wje.c"androidPositionLocked", live-since
  2026-05-29)`；远端键不在 defaults XML → 生产缺省 false；同旗门控
  `guf/m52/ofk/ot2/xnm` 全锁链。

## Harmony 缺口与实现

- 行序错位：CROP/EDIT_MATH 殿后、DELETE 居中、SEND_* 序颠倒、
  LOCK/DESELECT 位次不符 → `buildSelectionMenu` 重排为 urf 平铺序
  （fail-closed 项维持缺省；PASTE 维持剪贴板簇位登记适配）。
- SEND_* 无条件 → 新 `canReorder` 门：isf 型 && 所有选中叶子 ∈
  已选组成员并集（`isf.q` 空等价）→ 隐藏四行；jsf/lsf 恒显示。
- LOCK 注释补记 `h35.I`/`androidPositionLocked` 旗门（已移植+旗门
  登记，同 textOnly 判例）。

## 有意差异登记

- MORE 子菜单按原序平铺至单行尾段（`msc.b` 双行 showSubmenu 的已
  登记适配，无原生双子菜单菜单容器）。
- isf 单成员退化分支反编译折行歧义（`wqfVar3=null` 折叠点可能使单
  非组成员挂 UNGROUP 死行；`dhb` case5 对该路径静默 no-op）——不
  移植疑似死行，Harmony 无行。
- PASTE 在 DUPLICATE 后（原版为画布浮动条 `t6b`，菜单内无此项）。

## 验证

- 目标 fixture `d02-selection-menu-urf-order.mjs`：25/25 green
  （17 项相对序断言 + 门控/旗注/镜像/文档闭环）。
- 全量 Desktop Replay 基线：见下段。
- `note@default` / `note@ohosTest`：见下段。

## 关联文档

- 证据：`docs/migration/evidence/phase-1440-selection-menu-order.md`
- ADR：`docs/migration/adr/ADR-1375-selection-menu-order.md`
- 前置：P1439 DESELECT isf 门（ADR-1374）；菜单枚举登记 ADR-0645；
  STICKER 旗 ADR-1364/1371。

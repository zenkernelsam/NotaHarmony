# Phase 1441 — 选择菜单实体专属行 lsf 门控 + 已锁单行菜单（证据）

## 原版证据（decompiled_1.4.2 `urf.java` / `wqf.java`）

### `hv6VarP1` 的推导路径（urf.java:243-262 起装配段内）

```java
lsf lsfVar2 = msfVar instanceof lsf ? (lsf) msfVar : null;
hv6 hv6VarP1 = lsfVar2 == null || (r0bVarC2 = urfVar.C()) == null
    ? null : zq.p0(r0bVarC2, lsfVar2.a, i2);   // i2 = 6
```

`hv6VarP1` **仅当 msfVar 为 `lsf`（单元素点选）时非空**；`isf`（绘制/集合）、
`jsf`（组点选）、`hsf`（进行中套索）下恒为 `null`。

### 三处消费 `hv6VarP1` 的行装配

| 行 | 条件 | 含义 |
|----|------|------|
| `CROP` | `hv6VarP1 instanceof l97` | lsf 且单实体为图像 |
| `EDIT_MATH` | `hv6VarP1 instanceof cv9` | lsf 且单实体为数学 |
| `FLIP_H`/`FLIP_V` | `z6 = hv6VarP1 instanceof l97` | lsf 且单实体为图像 |

因此 **套索恰圈一个元素的 `isf` 选区不产 CROP/EDIT_MATH/FLIP 行**——
基数 1 不足以致能，必须是 `lsf` 点选来源。多元素 `isf` 更不可能。

### z 支：已锁单元素 → 仅 UNLOCK（urf.java:247-258 + ~268）

```java
if (h45.b(h35.I)) {            // POSITION_LOCKED td5 灰度旗（P1440 已登记）
  lsf lsfVar = msfVar instanceof lsf ? ... ;
  if (lsfVar == null || (hv6VarP0 = zq.p0(r0bVarC, lsfVar.a, 6)) == null
      || !cjm.h(hv6VarP0)) {   // cjm.h = 实体已锁
    z = false;
  } else { z = true; }
} else { z = false; }
…
xqfVar = z ? new xqf(oag.x2(wqf.Y), …) : …;   // wqf.Y = UNLOCK 单行
```

旗开语义下：点选已锁实体 → 菜单**仅 `UNLOCK` 一行**（锁定元素不可样式/
删移/翻转——只能解锁）。

### 版本差异登记

`h35.I` = `td5("androidPositionLocked")` RemoteConfig 灰度旗（live-since
2026-05-29），defaults XML 无此键 → 生产缺省 `false`（P1440 已登记）。
按 P1438 textOnly 先例：**已移植语义按旗开实现**，旗门事实记入文档；
1.0.3 旧名 `ac4.Q(POSITION_LOCKED)`/`lg2` 不再作为行为事实源。

## Harmony 现状缺陷（修复前）

1. `canFlipImageSelection`：仅按类型/基数判——`isf` 单元素图像或多图集合
   均放行 FLIP；原版 lsf+单图专属。
2. `canCropImageSelection`：`imageIds.length===1` 即可——isf 单图误放行。
3. `selectionCanEditMath`：`mathIds===1` 即可——isf 单数学误放行。
4. 点选已锁元素仍显全菜单——原版旗开时仅 UNLOCK。

## Harmony 修复（本 Phase）

`note/src/main/ets/ui/editor/NoteCanvasView.ets`：
- `selectionCanFlip`/`selectionCanCrop`/`selectionCanEditMath` 均以
  `!state.supportsDeselectMode`（非 isf 型 = lsf/jsf；jsf 另被自身
  `groupIds>0` 排除）前置——与 `hv6VarP1` 的 lsf-only 推导对齐。
- `canFlipImageSelection` 收紧为 `imageIds.length === 1`（l97 单实体）。
- 新增 `selectionLockedOnly = !isf 型 && 无组 && 恰一可锁实体 && 已锁`。

`note/src/main/ets/ui/components/SelectionOverlay.ets`：
- `@Prop lockedOnly`；菜单装配中 `lockedOnly` → 仅 `UNLOCK` 单行早退，
  位于 CROP 等实体专属行之前（对齐 `xqf(oag.x2(wqf.Y),∅)` 单元素菜单）。

## 不变量保护

- `jsf`（组点选）：`groupIds>0` 天然被三门排除 + lockedOnly 的
  `selectedGroupIds.length===0` 排除——与原版 jsf 无实体专属行一致。
- `isf` 单元素（套索圈一元素）：三门全关 + DESELECT/SEND_* 照常——
  与原版 `hv6VarP1=null` 一致。
- `lsf` 点选：三门照常 + 已锁时仅 UNLOCK——与原版一致。
- 变换/裁剪重断言 `selectElementIds`（undefined 保种）不受影响。

## 验证

- 新 fixture `d02-selection-entity-rows-lsf-gate.mjs`：15/15 绿。
- 全量 Desktop Replay 基线 + `note@default`/`note@ohosTest` 构建见报告。

# 原版证据：选区常态 pointer-down 语义（wtc 拖拽 / vtc TapToSelect / rtc ClearSelection）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 590 依据；**修正 Phase 589 对 `stc`/`ej9 case18` 的误读**。

## 1. `ftc` 字段语义（纠正）

`ftc.java` toString：`Drawn(rect, finalizedRect, bounds, rotationRadians,
finalizedRotationRadians, inProgress=f, selectedIds=g, deselectMode=h,
deselectedIds=i, id=j, lassoPoints=k, finalizedLassoPoints=l, groups=m, n)`。

- `ftc` = **Drawn** 套索/矩形选区状态。
- `h` = **deselectMode**（点按移除模式），`i` = **deselectedIds**。
- `dhb.java:18035-18042`（cg2 case20）：菜单动作把 `h` 置 true——
  deselectMode 由菜单项进入，非常态。
- `ej9.java` case18（`stc`）：`ys2.H(ftcVar.g, set5)` 从 selectedIds 减去、
  `ys2.J(ftcVar.i, set5)` 并入 deselectedIds——**点按把元素移出选区**，
  是 deselectMode 语义，不是"抓取移动"。

## 2. `dl1.java` case2 常态（`h=false`）分发

```java
} else {                                    // h == false
    cmbVarA = htcVar.a();                    // 选区覆盖层几何
    if (yxi.e(cmbVarA, jE, htcVar.g(), fi3.b(cmbVarA))) {   // 覆盖层内
        if (!(htcVar instanceof gtc)) {
            ttcVar = new wtc(htcVar.d(), htcVar);   // → ej9(19) → e39 拖拽
        } else if (z2 || ufbVar.I.getValue() == null) {
            // gtc 组选择态：命中成员 → ttc(id,jE) → uw2 case4（元素菜单）
            //              未命中/非成员 → wtc 拖拽
        } else { ttcVar = utcVar; }                 // 消费无动作
    } else if (z3) {                                 // 覆盖层外
        ptcVarA2 = xtcVar.a(jE, null);               // 任意元素命中
        ttcVar = ptcVarA2 == null ? rtcVar           // 未命中 → ClearSelection
                                : new vtc(ptcVarA2); // 命中 → TapToSelect
    } else { ttcVar = utcVar; }
}
```

- `wtc` → `ej9(19)` → `e39`：`v39(cmb, ktc)` 经 `l51.i` 消费指针流——
  **整体移动选区**手势。
- `vtc` → `uw2` case3：`ntc`（`cqc` 组命中）→ `new gtc(qo5, setX2, cmb)`
  Group 选择态；`otc` 元素命中 → `fvbVar2.d(vndVar.I.getId())` 选中该元素。
- `rtc` → `ct0(xtc, z2, 3)`：ClearSelection。

## 3. deselectMode（`h=true`）分发

`stc`/`ej9 case18`：命中选中元素 → 从 `g` 移入 `i`（点按移除；组命中整组
移除）；覆盖层内 → `utc`；其余 → `qtc → z39` 新选区。

## 4. Phase 589 的误读与 Phase 590 纠正

Phase 589 把 `ftc.i` 误读为"moving set"并实现了元素粒度抓取拖拽。纠正：

| 原版 | Harmony（Phase 590 后） |
|---|---|
| 覆盖层内按下 → `wtc`/`e39` 拖整体 | `pointInRect(selectionRect)` → `selectionDrag` 拖全部选中（恢复 Phase 589 前语义） |
| 覆盖层外命中元素 → `vtc` TapToSelect | `topmostPageElementIdAt` + `resolveOriginalGroupSelection` → `selectElementIds` |
| 覆盖层外未命中 → `rtc` ClearSelection | `clearSelectionWithRegisterReset()` |
| `cqc` 组命中 → `gtc` 组选择 | 组展开经 `selectionGroups` + `groupIds` |
| deselectMode `stc` 点按移除 | **未移植**：Harmony 选区菜单无 deselectMode 入口（`dhb` case20），相关 `movingIds` 机制已随 Phase 590 移除，避免死代码 |

## 5. 有界偏差

- `yxi.e(cmb)` 是旋转感知的覆盖层命中（`htcVar.g()` 传 rotationRadians）；
  Harmony 用 AABB `selectionRect`——旋转选区下 AABB 内、旋转矩形外的点
  原版走 vtc/rtc，Harmony 走拖拽（仅旋转选区边角差异）。
- `gtc` Group 选择态内按成员元素的 `ttc → uw2 case4`（元素级菜单 `qke`）
  未映射——Harmony 组选择按 `wtc` 整体拖拽处理。

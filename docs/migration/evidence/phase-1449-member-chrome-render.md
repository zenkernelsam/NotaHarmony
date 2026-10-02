# Phase 1449 证据：1.4.2 `s40`/`gsf`/`xnm`/`qmm` 成员级选区铬件

## 原版证据（`decompiled_1.4.2/sources/defpackage`）

### 1. 选区渲染分发（`sen.java:1040-1055`）

```java
if (msfVar instanceof isf) {
    senVar.t(...);          // isf：外层界 + 轨迹 ghost
} else if (msfVar instanceof hsf) {
    gsf.d(...);             // 进行中手势：指针轨迹蚂蚁线
}
// sen.d 对 lsf/jsf 仅注册重组回调后返回 → 画布层不产外层界框。
```

- `lsf`/`jsf` 的外层界框不在画布层；jsf 外盒由 `gsf.h` 支产出（见下）。
- 分发仅 isf/hsf 两支：进行中手势（矩形模式同）恒走 `hsf.a` 轨迹。

### 2. 成员级铬件循环（`s40.java:c`）

```java
List<mp4> list4 = xnm.c(msfVar.f(), z2 /* lsf */);
for (mp4 mp4Var : list4) {
    gsf.c(mp4Var, f6, z2 && !mp4Var.d(), gsf.a);   // 成员框 ± 柄
}
qmm.d(list3);                                       // 成员路径描边
gsf.h(msfVar, f6, z2);                              // 外层铬件（组盒+柄）
```

### 3. 成员框来源（`xnm.java:c`）

- 仅 **图片 `l97`** 与 **文本 `vvh`** 成员产 `mp4` 框（旋转矩形）；
- `lsf` 且 `cjm.h`（实体锁）时对裁剪图调裁剪界；
- 数学块/组本身不产 `mp4` 框。

`mp4.d()` = `cjm.h(实体) && POSITION_LOCKED` → 框存在但不带柄。

### 4. 成员路径描边（`qmm.java:d`）

- 笔画 `mn7` 成员：实际轮廓路径（`mn7Var.S()` 大纲）以 `gsf.a` 蓝描边；
- 形状 `f5g` 成员：形状路径同样描边；
- 宽 `t1h(Math.min(m0(2dp)/f2, cpfVar.f / 2.0f))` ——
  `m0(2dp)/f2` = 2dp/zoom；`cpfVar.f` = `mn7Var.j0()`/`f5gVar.S()` 笔画宽；
- 尾部 `cpfVar.g` 点列（形状顶点圆点，lsf 形状时）——Harmony 未移植
  顶点圆点，登记差异。

### 5. 外层铬件（`gsf.java:h`）

```java
if (msfVar instanceof lsf || msfVar instanceof hsf) { return; }  // 不画
if (msfVar instanceof jsf) {
    c(jsfVar.a(), f2, true, e);     // e=#FFB3B3B3 灰实线 2dp 外盒 + 柄
}
if (msfVar instanceof isf) {
    for (tof tofVar : isfVar.m) {
        c(hsm.b(tofVar), f2, false, e);   // f()：组灰盒，无柄
    }
    if (!isfVar.h) { e(...); b(...); }    // 旋转柄 + 四角柄
}
```

- `c()` = `mp4` 旋转矩形 `t1h(2.0f/f2)` 实线描边；
- `e()` = 旋转柄（顶边中点上延线 + 圆 16dp 白 / 14dp `#FF444DE0`）；
- `b()` = 四角柄（白 12dp 圆 + `a=#FF4278FF` 10dp 圆）；
- `deselectMode`（`isf.h`）→ 外柄跳过（组灰盒仍绘）。

### 6. 颜色常量

- `gsf.a` = `qxk.e(4282546431)` = `#FF4278FF`（成员轮廓/成员框/isf 界）；
- `gsf.e` = `#FFB3B3B3`（jsf 外盒与 isf.m 组灰盒）；
- `gsf.d` = `#FF444DE0`（旋转柄内圆）。

## Harmony 对齐

| 原版 | Harmony（Phase 1449） |
|------|----------------------|
| `s40.c` 成员级循环 | `renderSelectionMemberChrome()`（元素层之上、外层界之下） |
| `qmm.d` 笔画/形状路径描边 | `customPath??fillPath`（缺省中心线）/`shapeWorldSubpaths` 逐子路径，`min(2dp/zoom, strokeW·‖M‖/2)` |
| `xnm.c` 图/文成员框 | `textBlockWorldCorners`/`imageBlockLocalBounds×transform` 旋转实线框 2dp/zoom |
| `gsf.h` jsf 灰外盒 | overlay `selectionOuterGray` → `#FFB3B3B3` 实线 2dp + 柄 |
| `gsf.h` lsf 早退 | overlay `selectionBorderless` 隐外框，成员铬件画布层承担 |
| `mp4.d()` 锁抑制柄 | `selectionHandlesHidden`：lsf 非图/文成员或已锁成员无柄 |
| `gsf.f(m)` 组灰盒 | `selectedGroupIds` 逐组 `memberUnionBounds` 灰实线盒 |

## 登记差异

1. **组盒旋转**：原版 `mp4` 携带 `tof.g()` 组旋转；Harmony 组无存储旋转
   → 组灰盒为轴对齐并集（fail-closed，视觉近似）。
2. **形状顶点圆点**（`qmm.d` `cpfVar.g`）：未移植，登记为后续候选。
3. **数学块 lsf**：原版无成员铬件亦无外框——选中态仅菜单可见，
   Harmony 对齐（`borderless` + `handlesHidden`）。

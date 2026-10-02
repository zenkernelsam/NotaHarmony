# Phase 1451 证据：1.4.2 `qmm.d` `cpfVar.g` lsf 形状成员顶点圆点

## 原版证据（`decompiled_1.4.2/sources/defpackage`）

### 顶点集装配（`qmm.java:b` z 支，451-476）

```java
// 笔画 mn7 成员：arrayList = em4.F（空——笔画永不产顶点圆点）
// 形状 f5g 成员：
if (z) {   // z = msfVar instanceof lsf（s40.java:1198/1214）
    List listB = f5gVar.U().b();    // 形状几何顶点集
    arrayList = new ArrayList(f52.U2(listB, 10));
    for (e8d v : listB) arrayList.add(new s64(ec2.j0(v)));
}
```

**仅 lsf（点选型单元素选区）的形状成员产顶点圆点**；isf/jsf 下
`z=false` → `cpf.g` 恒空。

### 顶点绘制（`qmm.java:d` 577-589）

```java
float fA = gsf.a(f, qe4);             // = m0(6)/f × 1.25 = 7.5dp/zoom
float fM1 = qe4.m0(6.0f) / f;         // = 6dp/zoom
for (s64 v : cpfVar.g) {
    qe4.u0(qe4Var, gsf.b, fA, v, ...);   // 白圆（gsf.b=0xFFFFFFFF）
    qe4.u0(qe4Var, gsf.a, fM1, v, ...);  // 蓝圆（gsf.a=#FF4278FF）
}
```

### 各形状顶点集（`m4g.b()` 族）

- **LINE**（`m4g.b` q89=Line）：直/曲——
  - 直线（无控制点）：`[o()=start, n()=end]`；
  - 二次（仅 cp1）：`[o, mrd 三次近似 c(0.5), n]`；
  - 三次（cp1+cp2）：`[o, 0.125n+0.375cp2+0.375cp1+0.125o 加权中点, n]`。
- **ELLIPSE/矩形类**（`k4g.b` jza）：包围盒四基向点
  `(w/2,0),(w/2,h),(0,h/2),(w,h/2)`。
- **POLYGON**（`l4g.b` p9d）：`vpm.c0()` = 全部顶点。

## Harmony 对齐

`renderSelectionMemberChrome` 内 lsf 判定（`!supportsDeselectMode &&
selectedGroupIds==0 && memberCount==1`）+ `shapeVertexDots(shape)`：

- LINE：`[start, 0.125/0.375 加权贝塞尔中点（有控制点时）, end]`；
- POLYGON：`vertices` 全部；
- ELLIPSE：`center ± radiusX/radiusY` 经 `rotationRadians` 旋转的四基向点；
- 各点乘 `shape.transform` 至世界坐标；白 `7.5/zoom` + 蓝 `6/zoom`
  双层实心圆。

## 登记差异

- `qmm.d` 每成员的第二路径 `cpfVar.e`（`cb0VarA.b` = 形状偏移轮廓）
  本阶段亦已随主轮廓一并描边——`shapeWorldSubpaths` 输出等价于
  `d+e` 两路径的联合呈现。
- `f5g.U()` 其它子类顶点集若存在未识别的特殊形状类型，按三类覆盖。

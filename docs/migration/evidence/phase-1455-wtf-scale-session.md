# Phase 1455 证据 — 角柄 wtf(Scale) 会话（ms1:295-435 / guf.f / guf.h）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### 角柄命中（ms1.java:295-327）

```java
// sbeVarO2 = guf.o(msf) 选区界；u64.c(sbe) 产 4 角点列；
// f10/f11/f12/f13 = left/right/top/bottom
float f15 = guf.l / gufVar.k;          // 44/zoom（文档系命中半边长）
for (四角) {                            // 最近角优先
    fD = s64.d(xxb.f(jC, corner));     // 距离
    ...
}
// 命中校验：|dx|<f15 && |dy|<f15 轴对齐方框（非圆）
fIntBitsToFloat3 >= fE3 && < fE4 && fIntBitsToFloat4 >= f16 && < f17
```

### wtf 构造（ms1.java:330-435）

```java
stf stfVar = stf.G.get(iNextInt);      // 0=TL 1=TR 2=BL 3=BR
f18 = f13 - f12;  // 高；f19 = f11 - f10;  // 宽
jA  = s64.a(±f19, ±f18);               // axis：对侧角→拖拽角对角向量
jC4 = s64.a(±f19, 0);                  // xAxis
jC5 = s64.a(0, ±f18);                  // yAxis
jA4 = ordinal0→(f11,f13) / 1→(f10,f13) / 2→(f11,f12) / 3→(f10,f12)
                                       // = 对侧角 fixedCorner
z7: 默认 true；z5(lsf) ∧ 元素 instanceof vvh → false（自由拉伸）
// f!=null 时轴向量经 kw9.a/h/c 按选区旋转旋入旋转系
gufVar.h = new wtf(getId, mapI, jE, jA, jC4, jC5, z7, j7, jE, msfVar);
```

`wtf` toString：`Scale(stateId, originalPositions, dragStartPoint,
axis, xAxis, yAxis, locksAspectRatio, fixedCorner, transientOpId,
lastDragPoint, initialSelectionState)`——**无角度字段**。

### guf.f（guf.java:67-75）— 缩放比计算

```java
jL = wtf.l() = xAxis; jM = wtf.m() = yAxis;
sx = |xAxis|²==0 ? 1 : (xAxis + j)·xAxis / |xAxis|²   // = 1 + Δ·xAxis/|xAxis|²
sy = |yAxis|²==0 ? 1 : (yAxis + j)·yAxis / |yAxis|²  // j = cur−dragStart
// fom.a 打包 (sx,sy) 双浮点返回
```

### guf.h（guf.java:280-354）— 逐成员应用

```java
// 每成员：(elemPos − page − pivot) → 逆元素旋转 → ×(fD2,fC2)
//         → 正旋回 → +pivot + page → 新 pos；
// fD2 = max(16/(fontD·fD), sx)  jv6 文本 16px 字号下限；
// f3 = fD·fD2 → mrm.a(vpm.b(f3,f4)) 缩放操作；
// z=true → a() 页框钳制（越界回退页内）。
```

对照 `guf.m`（同签名）：单标量 f 双轴等比 + f2 旋转 + 枢轴 j——
为 utf 捏合会话应用（uniform scale + rotate）。`h` 双轴版 = wtf 支。

## Harmony 映射

| 原版 | Harmony |
|------|---------|
| `wtf.c=dragStartPoint` | `resizeStart` = 实际触点（Δ 自触点起算） |
| `axis` 对角向量 | `resizeAxisX/Y` 带符号幅（AABB 退化） |
| `xAxis`/`yAxis` | 同上（θ=0 模型下与对角分量一致） |
| `locksAspectRatio` z7 | `resizeFreeScale`（lsf+单文本→true） |
| `fixedCorner` | `resizeAnchor` = 对侧角 |
| `guf.f` 投影 | `1+Δ·axis/|axis|²`（锁）/`1+Δx/axisX` 等（自由） |
| `guf.h` 双轴应用 | `resizeSelectedAxes(sx,sy,anchor,base)` |
| `f15=44/zoom` 命中方框 | `SELECTION_CORNER_HIT_HALF=44vp` 方框 |
| jv6 16px 字号下限 | **未实现——ADR-1390 登记** |
| 页框钳制 a() | **未实现——登记** |
| 选区旋转系轴 | AABB 退化 θ=0——登记 |

## 关键裁决

- **角柄不产旋转**：wtf 字段/应用路径均无角度——终结 Harmony
  沿用 1.0.3 htc.e 的角柄自由旋转（版本演进差异坐实）。
- **命中域 88vp 方框** 替代 Ø44vp 圆（f15 半边长语义）。
- **拖过对侧角翻转**：h() 无符号钳制——保留负缩放翻转语义。

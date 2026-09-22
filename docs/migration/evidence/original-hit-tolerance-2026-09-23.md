# 原版证据：元素命中两程 ±5 容差（fu1.e）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 606 依据。

## 1. 两程命中（fu1.java:270-295）

```java
public final vnd e(long j, x09 x09Var, Set set) {
    List listM0 = m18.m0(v09.M, v09.N, v09.K, v09.L);      // SHAPE+BLOCK+ANIM+INK
    vnd vndVar = (vnd) au1.o1(f(new vh5(j),              // 第一程：点查询
        new k11(ei3.e(j), ei3.f(j), ei3.e(j), ei3.f(j)), // 精确点矩形
        listM0, x09Var, set));
    if (vndVar != null) return vndVar;
    k11 k11Var = new k11(ei3.e(j) - 5.0f, ei3.f(j) - 5.0f,
        ei3.e(j) + 5.0f, ei3.f(j) + 5.0f);               // 第二程：±5 矩形
    vh5 vh5Var = new vh5(j, 5.0f);                       // 半径 5 查询圆
    ...                                                  // o1 取 z 序最上
}
```

## 2. 容差语义（fu1.java:454-505 `g`）

- **块（oy0 = hp5 图片 / xhe 文本 / r08 数学）**：本地半长 `gi3.c(jA)+fB`、
  `gi3.b(jA)+fB` ——`fB` 为查询半径经元素缩放归一后的**本地**值。
- **形状（m4d/n5d）**：`z8a.b(path, n5dVar.Q())` 描边带与查询圆相交；
  填充形另有内部命中。
- **tape（s06）/笔迹**：查询圆与笔带宽相交。
- 容差单位 = **世界/page 单位**：`fu1.j`（fu1.java:244）将查询圆半径
  按元素缩放归一——`vh5Var.b() / Math.max(qedVarB.d(), qedVarB.c())`，
  即元素本地容差 = `5 / maxScale`。块本地半长 +`5/scale` 与此等价；
  笔/形世界半径 = `localWidth·scale/2 + 5` 亦同价。

## 3. tape 收集与回退（xtc.java:39-74 `b`）

- 门控：`a(j,null)`（即 `fu1.e` 两程）顶层命中须为 `otc` 且 `I.k()`
  （tape）；组（`ntc`）不触发。
- 收集：`fu1.f(vh5(j), k11(点), [SHAPE,INK])` ——**精确**命中集，
  过滤 `I.k()`。
- 回退：`setX1.isEmpty() → ys2.P(otcVar.a().I.getId())` ——
  容差命中的顶层 tape 单例。

## 4. Harmony 缺口与修复

- `topmostPageElementIdAt` 只测精确点 → 补两程：exact→tol5
  （`hitOrderedElementIdAt(ordered, point, worldTol)`）。
- 容差单位 = 世界单位：块 `expandLocalBounds(bounds, worldTol, transform)`
  内以 `worldTol/maximumLinearScale(transform)` 转本地后四边扩张
  （`gi3+fB` 等价）；笔/形世界半径 = `localWidth·scale/2 + worldTol`
  （`hitStrokeAtPoint`/`pointHitsShape` 收 `worldTolerance` 参数）。
- `tapeIdsAtPoint` 精确收集为空 → 回退两程顶层 tape 单例
  （`isTapeElementId` 过滤）。
- 消费方（`applyTapSelect`、`textBlockLinkAt`、
  `insideOverlayElementTap`、`deselectTargetIdsAt` 等）自动继承
  两程语义，与原版共用 `xtc.a`/`xtc.c` 门控一致。

## 5. 偏差

- `vh5(j,5)` 的 5 为世界/page 单位；Harmony 画布坐标同单位制，
  视为等价（`ei3` 页单位）。初版实现误将 5 作元素本地单位
  （已按 `fu1.j` 缩放归一证据修正为世界单位）。

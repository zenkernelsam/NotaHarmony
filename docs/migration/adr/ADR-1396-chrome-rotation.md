# ADR-1396：选区外铬件壳旋转（gsf.c xke.s + isf.d/jsf.g + 旋转系命中）

- 状态：已采纳
- Phase：1461（结清 Phase 1449 登记差异「组灰盒轴对齐 / 无外盒旋转」）

## 背景

原版 `gsf.c(qe4, mp4, f2, z, j)` 绘外铬件前先
`((xke) dgeVarT0.G).s(mp4Var.b(), mp4Var.c())`——画布绕 **sbe 中心**
旋 **mp4.c()** 后，界（2dp 实线）、四角柄（gsf.b）、旋转茎柄（gsf.e）
**整体旋转**。`gsf.h` 分发时 isf 支取 `isfVar.d`、jsf 支取
`jsfVar.g()` 作壳旋转角；lsf/hsf 无外盒。命中侧 `ms1:295-327` 的
±f15 方框测试在 `kw9.c` 旋入的旋转系内进行。

Harmony 此前：覆盖层外盒+手柄恒按 AABB `selectionRect` 渲染；命中
亦按 AABB——与已有的 `yxi.e` 旋转系界内判定模型不一致（旋转选区
的 inside 命中已按旋转壳判，铬件却画轴对齐框）。

## 决策

1. **壳几何源复用**：`uniformRotationUnrotatedScreenRect()`
   （统一旋转成员的去旋并集屏框 + θ）即 mp4(sbe,θ) 等价物；
   `selectionChromeGeom()` 汇总：u≠null → 旋转壳，否则 AABB/0。
2. **渲染**：SelectionOverlay 铬件块画在未旋转
   `selectionChromeRect` 上，外层 Stack `.rotate(angle, center=框心)`
   ——等价 `xke.s(center,θ)`；菜单锚维持 `selectionRect` AABB。
3. **命中**：`unrotateChromePoint` 触点绕框心反旋 −θ，
   在未旋转壳上测 ±44vp 方框（角柄）与茎端点圆（旋转柄）；
   `selectionScreenCorners` 产旋转后屏角供 wtf 锚/轴推导。
4. **wtf 轴向量**：`resizeAxisVecX/Y` = 对角向量 D 在框轴单位
   向量上的分解（`wtf.xAxis/yAxis` 旋转系轴）；`resizeSelectedAxes`
   增 `shellRadians` 走 `R(θ)·diag(sx,sy)·R(−θ)` 共轭缩放——
   freeScale（lsf+vvh 文本块）在旋转壳上沿框轴正确缩放。
   AABB 下全部退化为既有标量式。

## 已知差异（登记延续）

- 含笔画选区：旋转烘进 `pathPoints` 无载体 → 壳 θ=0（与 yxi.e
  命中模型同款缺口；原版图层可携旋转）。
- `jsf.g()` 是组实体的持久旋转字段；Harmony `OriginalSelectionGroup`
  无旋转字段，以组叶子公共旋转代理——组内成员旋转一致时等价。
- 外盒菜单仍锚 AABB 顶中（原版 Compose 菜单位置未逐一取证）。

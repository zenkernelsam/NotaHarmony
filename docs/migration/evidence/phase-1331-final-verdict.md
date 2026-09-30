# Phase 1331 证据 — 深度重审最终裁决

来源：`FINAL-REVIEW-PROMPT.md` 全项目深度重审；Phases
1296–1330 完成原版普查+Harmony 覆盖+保真度审计。

## 重审四节全部覆盖

### A. 算法保真（vs `reference/defpackage` 基线）

| 算法 | 原版基线 | 裁决 |
|------|----------|------|
| ForceSmoother | ws4/dr4 | EMA 8ms+0.15 钳制 保真 |
| CubicFitter | sqh.f/wy5 | 最小二乘+>200pt 二分分段 保真 |
| ShapeDetector | b90/b16.h | hold 检测 0.6/60/120px 保真 |
| WidthOutlineBuilder | w4a/y5a | 法向偏移+圆头帽 保真 |
| PencilSplatGenerator | xaa/oz5 | LCG 散布+压感⁵+T-033 保真 |

### B. 渲染正确性

- 部分橡皮 = 几何裁剪实体拆分（`w4b`/`h4f` clip）；
  destination-out 合成 + 脏区 clip（1330）。

### C. 数据一致性

- 序列化 = float32-LE 无损往返 + FlatBuffer op 往返
  （1329）；CRDT `exc.A0` 序+64-bit pack 字节保真（1309）。

### D. 覆盖矩阵

- 9 顶层目录 ~300 ETS 全审；`haa` 30-op 全覆盖（1323/1324）。

## 最终裁决

**Harmony 移植为忠实移植**：CRDT 线格式+排序比较器+
FlatBuffer 信封与原版字节互操作；`glmath` 真原生移植；
`.note` iOS 格式完整；部件逐字节保真。

**fail-closed 差距**（文档化，非缺陷）：OAuth、IAP、
实时转写、MyScript 引擎、部分 analytics、360-video。

## 产出

- 本裁决文档；全基线 1187+ fixtures 绿。

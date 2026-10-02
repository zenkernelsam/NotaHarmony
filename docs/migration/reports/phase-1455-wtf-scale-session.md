# Phase 1455 报告：角柄 wtf(Scale) 会话——双轴缩放 + fixedCorner 枢轴 + 无旋转

## 触发

Phase 1453 登记差异：`wtf` 字段无角度但 `guf.r/s` 反编译失败，
角柄缩放+旋转合并语义未确证。本 Phase 绕过失败方法，
经构造点 + `guf.f`/`guf.h` 两条完整函数坐实语义。

## 原版证据链

1. **`ms1.java:295-327` 命中**：`u64.c(sbe)` 四角最近者优先，
   `|dx|<f15 ∧ |dy|<f15` 轴对齐方框，`f15=guf.l(44)/zoom`。
2. **`ms1.java:330-435` 构造**：`stf` 枚举定四角；`jA`=对角向量、
   `jC4/jC5`=宽高轴（经 `kw9.c` 旋入选区旋转系）、`jA4`=对侧角；
   `z7=locksAspectRatio` 默认 true、仅 lsf+vvh 文本块 false。
3. **`wtf` toString**：`Scale(...)` 无角度字段——角柄不产旋转。
4. **`guf.f:67-75`**：`sx=1+Δ·xAxis/|xAxis|²`、sy 同式
   （位移投影轴比，`fom.a` 打包双轴）。
5. **`guf.h:280-354`**：逐成员 `fixedCorner` 枢轴双轴缩放
   （含 jv6 文本 16px 下限、页框钳制 `z` 支）。
6. **对照 `guf.m`**：单标量+旋转角版 = utf 捏合会话。

## Harmony 修改

- `NoteCanvasView`：`resizeAxisX/Y`（带符号轴幅）+
  `resizeFreeScale`（lsf 单文本→true）；角柄支 `resizeStart`=
  实际触点；`applySelectionResize` 拆旋转柄/角柄两支——角柄
  `Δ` 投影产 sx/sy（锁等比走对角投影），经 `resizeSelectedAxes`
  绕 fixedCorner 应用，**无旋转**；命中改 ±44vp 方框。
- `SelectionTool`：新增 `resizeSelectedAxes`（`T(a)S(sx,sy)T(−a)base`）。

## 登记差异（ADR-1390）

文本 16px 字号下限、页框钳制、选区旋转系轴（AABB 退化）、
`guf.r/s` 未解码——lock 等比公式为 `axis` 字段角色推断
（与 `guf.f` 数学同构，置信度高）。

## 验证

- `d02-original-scale-session-wtf`：20 项绿。
- `d02-original-selection-resize`：36 项绿（断言全面更新）。
- `d02-original-selection-rotate-snap`：13 项绿。
- 全量基线 / 双 HAP：随提交前流程执行。

## 遗留

- RTL 左柄 `yj8.G` +π 起始角（P1453 登记，依赖 RTL 环境探测）。
- utf 捏合会话（`guf.m` 等比+旋转、twm.d 吸附）——无双指变换面。

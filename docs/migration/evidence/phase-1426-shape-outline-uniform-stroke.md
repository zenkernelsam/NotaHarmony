# Phase 1426 证据：SHAPE 描边 = px5.a Standard 均匀宽（对 ADR-1361 误判的纠错）

## 缘起

Phase 1425/ADR-1361 曾记录一条"剩余差异"：以为原版 SHAPE 描边经
`ox5(aj1.a, aj1.b)` 应用凿尖角/扁平度，而 Harmony 固定线宽——判为缺口。
本期复核证据链后确认该判断有误，SHAPE 描边在原版即为均匀宽。

## 纠错证据链（decompiled_1.4.2）

1. **`psi.java`（SHAPE 工具状态）**：字段 = {a,b,c, g92 d, r2k e, **r5g f**}。
   无 `aj1` 字段——SHAPE 工具根本不持有凿尖参数（`sri` 才是带 `aj1 f`
   的 CALLIGRAPHY 状态；Phase 1425 的注释把两者混淆）。

2. **`cc3.java` 默认样式表**（`G()`/`H()` 两套 `zsi` 注册表）：
   全表唯一 `aj1` 非空项是 `eti.G` = CALLIGRAPHY（`new aj1()`，
   即 π/2、0.75、stabilization=true 缺省）。`eti.T` = SHAPE 的默认
   `zsi`（cc3.java:238）显式传 `aj1Var = null`。

3. **`lnc.u()`（图形描边路径构建）**：`j1kVar.d.h`（= 元素样式 `zsi.h`
   的 aj1）非空才 `new ox5(a, b)`；SHAPE 元素恒 null → `px5.a`。

4. **`k9m.b()`**：`px5` instanceof → `jmc.c(f01, d)`（均匀宽路径）；
   `ox5` → `jmc.b(f01, d, angle, flatness)`（凿尖调制路径）。

5. **`svi.java:211`**：元素持久化的 nib 三列（15-17）仅在创建工具
   携带 aj1 时非空——SHAPE 创建的图形元素该三列恒 NULL。

## 结论

原版 SHAPE 描边 = `px5.a` Standard = 均匀宽圆头 stroked path
（DASH/DOTS 线型由 `so7` 另行叠加，`lnc.u` 的 `z` 参数对应）。
Harmony `ShapeCanvasRenderer.strokeShape` 的固定 `setLineWidth` +
round cap/join + DASH/DOTS 虚线即为精确对等——**无缺口，无需实现**。

## Harmony 侧复核

- `ToolState.nibAngle/nibFlatness` 注释与写入均限定 CALLIGRAPHY
  （`eti.G`），SHAPE 无 nib setter/panel——与 psi 无 aj1 对齐。
- `renderSpec.nibAngle` 仅 `currentTool === CALLIGRAPHY` 时非 null。
- SHAPE 次级条（iw4 case8）仅含种类行，无 ij1 nib 面板——原版
  ij1 面板仅挂 `sri`/`hri`（CALLIGRAPHY）分支（iw4 case0）。

## 回放

`d02-original-shape-outline-uniform-stroke.mjs`（9 项断言）：
均匀宽描边、无 nib 参与渲染、nib 状态/写路径 CALLIGRAPHY-only、
SHAPE 条无 nib 面板、纠错文档已落地。

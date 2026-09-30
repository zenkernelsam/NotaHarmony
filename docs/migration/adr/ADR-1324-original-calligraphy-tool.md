# ADR-1324 — 1.4.2 CALLIGRAPHY 凿尖笔：几何近似 + 数据忠实

- 状态：已接受
- 日期：2026-08（Phase 1388）
- 证据：`docs/migration/evidence/phase-1388-original-calligraphy-tool.md`

## 决策

以「凿尖（chisel-nib）几何近似」实现 1.4.2 新增的 CALLIGRAPHY 工具：

1. **工具语义忠实**：`ToolType.CALLIGRAPHY` 为独立工具（原版 `eti.G`，介于
   PEN/PENCIL 之间），默认进 Primary 托盘 index 1（升级 SQL `zmb.java:135` 与
   全新装 `cc3.G()` 一致）；无专属色井/宽井（`cc3.F()/I()` 均无 `eti.G` 行）。
2. **数据忠实**：`nibAngle`/`nibFlatness` 全程携带——`ToolState`（per-tool 配置）、
   `RenderSpec`（笔画渲染）、ink Create/Modify op 的 uint16 定点解码
   （`xal`：angle·2π/65536、flatness/65535）。默认 nib = `aj1.java:48`
   （angle=π/2、flatness=0.75、stabilization）。
3. **渲染几何近似**：`WidthOutlineBuilder.nibScale(Δ)=sqrt(cos²Δ+f²·sin²Δ)`
   （Δ=运笔方向−nibAngle）按"椭圆凿尖截面的方向投影"调制半径。
   **门控于 `nibAngle≠null`**：非书法笔/旧笔画 nibAngle=null → `nibScale≡1`，
   渲染逐位不变。

## 理由

- 原版凿尖宽度的逐点曲线由 **Google Ink** 笔刷引擎内部生成（`CalligraphyNib` →
  brush pack + altitude-angle），未在反编译代码中暴露；逐位复刻不可达。
- 几何近似在最大/最小方向与原版语义一致（沿 nibAngle 最粗、垂直最细），中间
  连续过渡，是「接近原生体验」的合理移植。
- 门控设计保证零回归：所有既有工具（PEN/PENCIL/HIGHLIGHTER/tape）nibAngle=null，
  轮廓构建逐位同前。

## 影响

- CALLIGRAPHY 出现在 Primary 工具箱（pen 之后），可选中、出笔、改色/宽、
  随 ink op 持久化与导入导出。
- 局部橡皮命中区、hold-整形均按笔族纳入。
- nib 角/扁率滑杆 UI（`calligraphy_angle/flatness`）未含——当前固定默认凿尖；
  后续可按 `foa NARROW/WIDE` 加预设选择。

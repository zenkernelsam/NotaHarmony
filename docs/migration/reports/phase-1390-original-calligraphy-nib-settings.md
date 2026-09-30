# Phase 1390 — CALLIGRAPHY 凿尖设置面板 + 每工具 STYLE 门控修正

## 目标

修正 Phase 1388 的 1.4.2 迁移缺陷：CALLIGRAPHY 已实现凿尖数据模型与渲染，
但缺其**专属设置面板**（`hri`/`ij1`）；且 STYLE 行被 `supportsBrushControls()`
错误显示给非 `n5h` 工具（CALLIGRAPHY/SHAPE/PENCIL/REVIEW）。

## 原版证据

- `k31.java:66-82`：settings 集按接口判定——`n5h`→STYLE、`sri`→CALLIGRAPHY、
  `wsi.e()`→tool 专属性。仅 `csi`(PEN)/`wri`(HIGHLIGHTER) 实现 `n5h`。
- `psi`(SHAPE)=`{SHAPE_KIND}`、`esi`(PENCIL)=`{COLOR,WIDTH}`、`jsi`(REVIEW)=`{TAPE_PATTERN}`
  ——均无 STYLE。
- `ij1.java`：凿尖面板——角度滑块 `a0(15, ju7(-60,60,1))`=**-60..60° 步15（9 档）**；
  扁率 `a0(20, ju7(0,0.95,0.05))`=**0..0.95 步0.05（20 档）**+Reset；Stabilization 开关。
- `q6i.java:117`：角度显示 = `toDegrees(nibAngle − π/2)`。
- `pxi.java`：`wp(int°)`=angle、`is5(float)`=flatness、`g0c(bool)`=stabilization。
- `aj1.c`：`CalligraphySelection(nibAngle, nibFlatness, nibStabilization)`。
- `zmb.java`：CALLIGRAPHY 种子 `stabilization=1`。
- `svi.java:179`：`ToolStateEntity.stabilization INTEGER` 持久化。

## 实现

| 层 | 变更 |
|----|------|
| ViewModel | `calligraphyStabilization` 状态 + applyActiveState 载入；`supportsBrushStyleControls()`（仅 PEN/HIGHLIGHTER）；`setCalligraphyNibAngle/Flatness/Stabilization`（calligraphy 守卫） |
| 渲染 | `RenderSpec.stabilization`（瞬态）；`StrokeSession` 位置 EMA `stabilizePosition`（α=0.45），仅 `===true` 启用 |
| UI | `CalligraphyNibPanel.ets`（角度/扁率滑块+Reset+防抖开关）；`EditorToolbar`：CALLIGRAPHY→NibPanel，PEN/HIGHLIGHTER→Style行 |
| 资源 | `calligraphy_angle`/`calligraphy_flatness`/`stabilization`/`reset`（base+zh_CN） |

## 验证

- Replay `d02-original-calligraphy-nib-settings.mjs`：44 检查全绿。
- `note@ohosTest` clean、`note@default` 构建成功，无新增 ArkTS 错误。
- 全量 Desktop Replay 基线 1242/1242 绿（见最新提交）。

## 差异

防抖动以位置 EMA 近似原版 Google Ink 私有平滑算法（ADR-1326），非逐位复刻。

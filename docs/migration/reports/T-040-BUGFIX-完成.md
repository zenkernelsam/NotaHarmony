# T-040-BUGFIX 完成报告（用户反馈 5 个 Bug）

> 工人: 编码助手 | 日期: 2026-08-07 | 状态: 待指挥官复核

## 修复清单（5/5 全部修复并模拟器验证）

| # | Bug | 根因 | 修复 | 验证 |
|---|-----|------|------|------|
| 1 | 铅笔不像铅笔（圆点连在一起） | **splatTexture 从未设置**——所有 Pencil splat 用 fallback 实心圆渲染；且无颗粒纹理 | **程序化铅笔纹理**（64×64：径向渐变中心浓边缘淡 + 900 个确定性 LCG 石墨颗粒，对照原版 uaa/PencilSplatRenderer 的 BitmapShader 质感）；onCanvasReady 时生成并设置 | ✅ 截图亮度分析：笔画内有亮度变化（10~71），非纯实心圆；修复前为均匀实心圆点 |
| 2 | 笔画可画出画布 | 输入坐标无边界限制 | **toRawPointerEvent 坐标 clamp 到纸张范围**（与 PaperRenderer 居中一致的画布坐标 [paperX, paperX+pw]×[paperY, paperY+ph]，含横向/缩放场景） | ✅ 长距离向左 fling（终点纸张外 x≈80）→ 笔画停在纸张边缘 x=180（≈192−半宽 12px） |
| 3 | 缩放控制条显示在屏幕中间 | **Row 上的 .align 是 Row 内容对齐，在 Stack 中无效** → 控制条按 Stack 默认居中 | **Stack({ alignContent: Alignment.BottomStart })** + 控制条 margin（left 16, bottom 68 避开 PageManagerBar） | ✅ UI dump：控制条位于左下角 (36,1177)，百分比/按钮正确 |
| 4 | 适应宽度后纸张飞右下角 | **setZoom 内部 zoomAt(0,0) 按比例缩放旧 scroll**，且 fitWidth 未重算 scroll → 纸张偏移 | **fitWidth 重算 scroll 使纸张水平/垂直居中**：scrollX = (w−paperW×zoom)/2 − paperX×zoom（paperX 为画布坐标纸张左缘） | ✅ 截图分析：纸张 x 192-2368（宽 2176 = 85% 画布），**中心 1280 完美居中** |
| 5 | FAB "+" 位置偏移 | Button('+') 的文本基线导致 "+" 视觉偏移 | **Button builder 形式 + Text 全铺满（width/height 100% + textAlign Center）**精确居中 | ✅ UI dump：Text 144×144 全覆盖按钮，居中 |

## 对照 1.0.3 原版说明

- **Bug 1**：原版（uaa/PencilSplatRenderer）用资源 BitmapShader 纹理提供铅笔质感；鸿蒙无该资源 → 程序化生成等效颗粒纹理（符合"尽量原生/自研兜底"原则）
- **Bug 2**：原版笔画限制在页面内（输入/渲染边界）；鸿蒙端在输入层 clamp（最接近原版行为）
- **Bug 3/5**：ArkUI 原生定位/组件方案（Stack alignContent、Button builder + Text），未自绘
- **Bug 4**：视口数学修正（与 T-034 viewport 语义一致）

## 修改文件

- `note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets`（Bug 1：纹理生成）
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`（Bug 1 设置纹理 / Bug 2 边界 / Bug 3 Stack 定位 / Bug 4 fitWidth 居中）
- `note/src/main/ets/ui/library/LibraryPage.ets`（Bug 5 FAB）

## 验证

- ✅ check_ets_files 零错误（仅 deprecated 提示）
- ✅ build_project BUILD SUCCESSFUL
- ✅ 模拟器（MatePad Pro 11）逐项验证（截图/UI dump/像素分析，证据见 docs/migration/reports/t040-ui/21-27*.png）

## 遗留（非本次范围）

- 铅笔纹理颗粒对比度可进一步调优（原版有更明显的石墨颗粒；当前 opacity 偏低，真机可复验）
- 模拟器会话偶发切走/锁屏（环境不稳定，验证过程多次恢复）

# ADR-0027：TEXT resize-to-fit 编辑宽度物化

- 状态：Accepted（Harmony 编辑器适配）
- 日期：2026-08-11
- 关联：D-02、ADR-0021、ADR-0022

## 原版证据与边界

原版 `cie` 将 `resizesWidthToFitText` 保存为 TEXT 独立 register；`z5c.y()` 为文本编辑器生成
`RichTextFieldData(m4c, textOrigin, layoutWidth)`，`uje` 再把同一 layoutWidth 交给实际 layout。它证明编辑态必须使用明确的
排版宽度，且该宽度与 Block size、margins 和 paper inset 同源，不能让覆盖层永久停留在旧快照宽度。

Android 1.0.3 反编译代码没有暴露一个可照抄的“按字符回写宽度”函数，也没有在本地 UI 中找到切换该 register 的入口。因此
Harmony 不能用平均字符宽度或固定倍率冒充原版测量；适配应复用当前最终 renderer 的真实 Canvas font metrics。

`corner=ROUND` 的枚举和 LWW register 可以直接证明，但 Android consumer 中没有出现可证明的圆角半径。该像素半径继续独立待办，
本阶段不写猜测常量。

## 决策

`Canvas2DTextRenderer.measureNaturalWidth()` 使用与最终绘制相同的字体、字符 style run、显式换行、段落缩进和列表前缀计算最大自然
行宽，再加左右 content inset 并向上取整到完整像素。它不使用旧 blockWidth 进行换行，避免 resize-to-fit 自我锁死。

编辑覆盖层以独立 `editingTextLayoutWidth` 响应草稿变化；仅 `resizesWidthToFitText=true` 时更新。提交时重新以同一 renderer 测量，
`TextBlockTool.updateWidthToFit()` 同步写入 blockWidth 和变换后的 world bounds，并由既有 REPLACE_ELEMENT Undo 与页面保存事务持久化。
关闭开关、非有限测量或未修改文本均保持旧宽度。

## 验证与剩余边界

- `RendererStyle.test.ets` 以离屏 Canvas 对比实际 `measureText()`；`TextBlockGeometry.test.ets` 覆盖变换 bounds、关闭开关和 NaN。
- `d02-text-resize-edit.mjs` 锁定 live overlay、commit、world bounds 与失败门禁，全量 D-02 replay 应继续通过。
- 设备仍需验证输入法组合文本、光标稳定性、复杂字体 fallback、RTL/复杂 shaping 和 50%/100%/200% zoom。
- ROUND corner 像素半径、IMAGE/MATH、Tape/effects 与 NOTE_BUNDLE 内容 replay 仍未完成，D-02 不关闭。

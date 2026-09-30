# Phase 1369 — 工具条字形补齐 m4f 五层

## 摘要
`ho5` 每工具 `m4f(outline, highlight, shadow, overlay, fill)`；`tn8` 使能分支
按 `fill→overlay→highlight→shadow→outline` 叠层，`gt`/`tn8` 以 `iu1.b(alpha,
主题令牌)` 给 overlay/highlight 亮调、shadow 暗调（透明度随明暗分叉）。
Phase 1368 的两层近似升级为全五层：`ToolGlyphs.ets` 补齐 9 个合成工具的
highlight/shadow/overlay pathData，`ToolGlyph` 按序渲染并加 `dark` prop 驱动
透明度，亮层 #ffffff/暗层 #000000 近似主题令牌。ADR-1305 边界已解。
专项 d02-original-editor-toolbar-glyphs 91/91。

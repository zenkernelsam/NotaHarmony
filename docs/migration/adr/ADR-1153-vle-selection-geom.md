# ADR-1153：vle 选区几何管线

## 状态

已接受（Phase 1209）。

## 决策

`wh8` `android.text.Layout` 行/偏移几何 → ArkUI
`Paragraph` 行查询；`vle.G` 选区矩形 + `mv6.J`
视口裁剪 → 浮动选择菜单/手柄定位；`ip4` 矩形消费
→ `SelectionMenu` 定位回调。

## 理由

`vle.G` 同行 `cmb(min x, top, max x, bottom)` /
跨行 `wpe.j` 路径盒 + `mv6.J` 裁剪 + `ip4.f` 回调 —
`TextView` 手柄几何等价。

## 后果

Harmony 文本选区 = 段落行几何 + 视口裁剪 +
浮动菜单定位 —— 对齐原版手柄几何。

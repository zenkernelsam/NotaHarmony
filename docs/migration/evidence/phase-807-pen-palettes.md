# Phase 807 证据：笔色板包面（spen_* 调色板）移植

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/resources/res/values/arrays.xml`、
`decompiled_1.4.2/resources/res/values/strings.xml`、
`note/src/main/ets/data/PenPalettes.ets`（新建）、
`note/src/main/ets/ui/components/ColorPicker.ets`（扩展）

## 1. 原版 spen_* 色板面（两版逐字节一致）

`res/values/arrays.xml` 中 `spen_*` 数组共 70 项，1.0.3 ↔ 1.4.2 名称清单
完全相同：

### 默认自适应色条（3 组）

| 数组 | 色数 | 语义 |
|------|------|------|
| `spen_adaptive_standard_color` | 39 | 标准彩度族 |
| `spen_adaptive_light_color` | 65 | 浅色/粉彩族 |
| `spen_adaptive_dark_color` | 65 | 深色族 |

### 主题色板包

- `spen_setting_swatch_1..23`：23 个主题包，各 8 色（175 个去重色）
- `spen_setting_swatch_adaptive_1..21`：pack 1..21 的深色自适应变体
  （pack 22/23 无变体），如 pack1 `ff3636→c90000`、`252525→dadada`

### a11y 名面

`pen_palette_color_*` 196 个命名色（acid_green…）、`pen_swatch_color_*`
快取色条名、`ui_tools__color_hex` = `Color #%1$s` 通用色号标签。

## 2. Harmony 侧原状与改动

原状 `ColorPicker.ets` 固定 12 预设（收藏格/最近色/eyedropper 已移植）。
缺口：原版的三组自适应色条与 23 个主题色板包未移植。

### 移植内容

- 新建 `note/src/main/ets/data/PenPalettes.ets`：完整数据层——
  `PEN_STRIP_{STANDARD,LIGHT,DARK}`（39/65/65 色）、
  `PEN_PALETTE_PACKS`（23×8）、`PEN_PALETTE_PACKS_ADAPTIVE`（21×8
  + pack22/23 `null` 占位保持索引对齐）。
- `ColorPicker.ets` 新增"色板库"区：`Swiper` 分页浏览 23 个色板包
  （每页 4×2 色点网格），深色主题下优先取 adaptive 变体；
  点选走既有 `onFreeColor`/`setBrushColor` 通道。
- a11y：色点以 `pen_string_color_hex`（"Color #%1$s"/"颜色 #%1$s"）
  播报色号——即原版 `ui_tools__color_hex` 的同名同格式回退标签；
  新增 `pen_string_palette_library` 区段标题（EN+zh_CN）。

### 呈现差异登记

原版 Compose 内色板库的具体分页/承载容器经混淆不可完整恢复
（`d82` 等消费类仅存引用痕迹）；Harmony 实现采用 Swiper 分页承载
23×8 包结构，语义等价于"可浏览主题色板集合"。

## 3. 结论

笔色板数据面零版本差；Harmony 侧补齐色板库浏览面，12 预设快取条
保留不变，包数据与 a11y 标签实现对齐原版资源级事实。

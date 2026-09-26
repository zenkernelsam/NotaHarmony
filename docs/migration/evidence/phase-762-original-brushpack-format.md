# 原版 1.4.2 笔刷包（.brushpack）格式登记（Phase 762 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/assets/brushpacks/`（1.0.3 无此目录）
> 性质：1.4.2 版本差证据登记（ADR-0708"版本差·待审"细化）；无 Harmony 代码变更。

## 一、容器格式

`.brushpack` 为 ZIP 容器，固定三件+：

| 成员 | 内容 |
|------|------|
| `manifest.json` | 清单：`displayName`、`fallbackColor`（hex）、`fallbackWidthDp`、`tintable`（bool）、可选 `tintBlendMode`（如 `multiply`）、`tintAlpha` |
| `brush_family.proto` | **gzip 压缩的 protobuf**（`1f 8b` 魔数），笔刷族定义；解压后为粒子/图章笔刷参数流（浮点尺寸、间距、不透明度与枚举字段；rainbow 解出族名 `fun-a-unstable`） |
| `preview_well.png` | 工具井缩略图 |
| `preview_selection.png` | 选中态预览图 |

## 二、五包清单

| 文件 | displayName | fallbackColor | widthDp | tint | 备注 |
|------|-------------|---------------|---------|------|------|
| droidrocket.brushpack | Droid Rocket | #3F3F3F | 8.0 | multiply×1.0 | proto 44 KB |
| glitter.brushpack | Glitter | #999999 | 4.0 | （默认） | proto 530 KB（最大） |
| io.brushpack | Io | #666666 | 4.0 | （默认） | proto 264 B（最小） |
| music.brushpack | Music | #3F3F3F | 8.0 | multiply×1.0 | proto 160 KB |
| rainbow.brushpack | Rainbow | #666666 | 4.0 | （默认） | proto 188 B |

配套 UI 证据：`ui_tools__brushstyle_calligraphy`、
`ui_designsystem__calligraphy_{fill,highlight,outline,overlay,shadow}`
drawable 族——书法/粒子笔型选择器表面。

## 三、处置

- 资产与 manifest 纯本地，理论可移植候选；
- `brush_family.proto` 的字段语义需要 proto schema 还原（无缺省 .proto，
  需从 wire 结构或调用侧反推）+ 粒子笔刷渲染链评估——工作量独立成 Phase；
- 在 ADR-0708 框架下登记为"版本差·待审"，本阶段仅登记格式证据。

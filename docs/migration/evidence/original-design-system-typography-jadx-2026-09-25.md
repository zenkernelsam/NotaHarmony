# 原版设计系统字体（ar8/bv8/taa）证据（JADX, decompiled_1.0.3）

日期：2026-09-25。来源：`decompiled_1.0.3` JADX 输出 +
`resources/res/font/`。

## 结论

原版存在**两套独立字体体系**：

1. **笔记内容字体**（`qr4.java`）：Inter / Roboto / EBGaramond 三族
   —— 开源许可（OFL/Apache），已由 `NoteFonts.ets` 移植并经
   `registerFont` 注册（ADR-0675）。
2. **设计系统字体**（`ar8.java` + `bv8` + `taa`）：应用 UI chrome
   的标题/正文/等宽四族 —— **商业许可字体**，未移植，Harmony
   以系统字体（HarmonyOS Sans）呈现。本文件登记该边界。

## 原版注册表

`ar8.java`（静态初始化，14-25 行）：

| 字段 | 字体文件 | 字族 | 许可性质 |
|------|----------|------|----------|
| `a` | gtflairebasic_black | GT Flaire Basic Black（Grilli Type） | 商业 |
| `b` | gtflairebasic_extra | GT Flaire Basic Extra | 商业 |
| `c` | untitledserif_{regular,regular_italic,medium,bold} | Untitled Serif（Klim Type Foundry） | 商业 |
| `d` | proximasoft_{regular,medium,bold} | Proxima Soft（Mark Simonson） | 商业 |
| `e` | gtamericamono_bold | GT America Mono Bold（Grilli Type） | 商业 |

`ns4` 为字重枚举（M/N/P/Q/R ≈ Normal/Medium/Bold/Black 档）。

`bv8.java`（5-8 行）把四族再导出为 MaterialTheme 排版槽位
（`bv8.a(uz4)` 主题访问器），`taa.java` 静态构造 15 个
`zqe`（TextStyle）：

| 样式 | 字族 | 字号/行高(sp) | 用途痕迹 |
|------|------|---------------|----------|
| a | GT Flaire Black | 34/41 | 付费墙大标题 |
| c | GT Flaire Black | 42 | 付费墙 hero 标题 |
| g | GT Flaire Black | 28/25 | tier 名标题 |
| h | GT Flaire Extra | 38/41 | hero 副标 |
| f | GT Flaire Black | 16 | 小标题 |
| b/d/o | Untitled Serif | 15/17 | 正文衬线 |
| e/j | Untitled Serif | 12 | 说明衬线 |
| k/n | Untitled Serif | 14/21 | 正文衬线 |
| m | Untitled Serif Bold | 17 | 强调正文 |
| i/l | GT America Mono Bold | 12/14-17 | 等宽标签 |

## 消费面

- `taa.*` 直接消费集中在 `hye`（付费墙 composable）、`u8j`/`e32`
  （付费恢复/权限）、`gj9`（资料库卡片菜单）、`jri`（Learn 测验）。
- `bv8.a-d` 主题槽位消费面广（`nb`/`a4j`/`ari`/`yeh`/`ke1`/`s3j`/
  `v22`/`r22`/`d32` 等 149 处调用点），即 UI chrome 全局排版。

## 边界判定

- 四族均为商业许可字库，随 APK 打包属原版授权范围；提取后随
  Harmony HAP 再分发不具备同等授权依据 —— **许可边界，fail-closed**。
- 语义层无损失：全部文案、字号意图、字重层级、颜色由 Harmony
  系统字体表达；`qr4` 笔记内容三族（开源许可）已正常移植。

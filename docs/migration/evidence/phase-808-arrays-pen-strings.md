# Phase 808 证据：arrays/pen_string 面 + Rive 运行时版本更正

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/resources/res/values/arrays.xml`、
`decompiled_1.4.2/resources/res/values/strings.xml`、
`decompiled_{1.0.3,1.4.2}/sources/app/{rive,p000rive}/`

## 1. arrays.xml 非 spen 面

`arrays.xml` 全部数组名两版一致；除 Phase 807 的 `spen_*` 外唯一剩余
数组：

- `feature_learn__chat_card_headers`：7 条轮换提示语
  （"Where do you need help?" / "What do you want to learn?" /
  "Ask anything about your notes." / "What do you want to know?" /
  "What are you working on?" / "Where are you getting stuck?" /
  "What do you want to understand better?"）——Learn AI 聊天卡片
  的轮换引导文案，属 Learn 后端/AI 面（772/781/788 已登记
  fail-closed 边界），数组本身仅登记。

## 2. `pen_string_*` 字串族（8 keys，两版一致）

| key | 值 | 用途 |
|-----|----|------|
| pen_string_color | Colour | 颜色标签 |
| pen_string_color_picker | Colour picker | 取色器 |
| pen_string_color_spuit | Eyedropper tool | 吸色笔（S Pen 术语） |
| pen_string_comma | , | 分隔符 |
| pen_string_current_any | Current %s | 当前值标签 |
| pen_string_new_any | New %s | 新值标签 |
| pen_string_fixed_thickness | **Fixed thickness** | 固定粗细模式 |
| pen_string_variable_thickness | **Variable thickness** | 变化粗细（压感）模式 |

语义：笔设置面板标签——`fixed_thickness`/`variable_thickness` 是
**每工具压感响应模式**（固定宽度 vs 压感可变宽度）的用户开关文案；
`current_any`/`new_any` 为设置预览的"当前/新值"标签。

Harmony 侧：压感管线已通（`InkInputProvider` pressure 钳制），粗细
以 `WidthSlider` 定值；**未提供"固定/可变粗细"模式切换**——登记为
笔设置面差异（S Pen 生态设置项，属平台语境的笔设置面板）。

## 3. Rive 运行时版本更正

- 1.0.3：`app/rive/`（256 个 java 文件，未混淆命名空间）
- 1.4.2：`app/p000rive/`（485 个文件，`p000` 混淆前缀）

即 **Rive 运行时自 1.0.3 已内置**；1.4.2 为包名混淆化 + 运行时大版本
升级（文件数近翻倍）。`.riv` 动画资产两版 6 件同名逐字节同
（inky_2026_v32 + anim_grow/learn/memorize/productivity +
learn_confetti）。更正 Phase 791 暗示的"Rive 属 1.4.2 新增"口径。

## 4. 结论

arrays/pen_string 残余面闭合：Learn 轮换文案登记（fail-closed 语境），
笔设置"固定/可变粗细"模式登记为平台语境差异，Rive 运行时版本谱系
更正为存量升级。

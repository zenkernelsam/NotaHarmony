# 当前阶段启动 Prompt

> 当前阶段不是 Day 0 批量侦察，而是「审计收尾 + HarmonyOS 目标端 MVP 原型验证」。
> 已完成的资源枚举、SO 身份、Room 表、工具枚举等任务不要重复执行。
> 平台边界：Pen Kit、StylusFrameBoost 等来自华为 HarmonyOS SDK；除非找到 OpenHarmony 上游文档，不得写成 OpenHarmony 通用能力。

---

## 使用前提

每个执行者先读：

1. `C:\Users\Cisco He\Desktop\Notability\COMMANDER.md`：当前任务、状态和协作规则。
2. `C:\Users\Cisco He\Desktop\Notability\REVERSE_ANALYSIS.md`：当前技术结论和证据索引。
3. 若任务涉及环境复现或动态验证，再读 `C:\Users\Cisco He\Desktop\Notability\ENVIRONMENT_SETUP.md`；注意脚本同时存在 spawn 与 attach 两种模式。
4. 若任务涉及交接、开工判断或阶段总结，再读 `C:\Users\Cisco He\Desktop\Notability\PROJECT_HANDOVER.md`。
5. 若任务涉及启动、登录或导航，再读 `C:\Users\Cisco He\Desktop\Notability\LOGIN_BYPASS_RETROSPECTIVE.md`；v14 已在本地模拟器验证，不要从 v1 重新试错。
6. 若任务涉及 UI、页面入口或一比一移植，重点读 `REVERSE_ANALYSIS.md` 第 39 节；Frida fake user 只用于进入真实页面，不属于目标端产品实现。
7. 若任务涉及目标端实现，先确认 HarmonyOS 工程根目录、DevEco/SDK/API level 和目标设备矩阵。当前工作区尚无 ArkUI/Hvigor 工程，常见安装目录/PATH 也未发现 DevEco/HDC/OHPM/Hvigor；未就绪时应先完成工具链与工程骨架，不得假定构建环境已经存在。

事实优先级：

```text
反编译代码/运行结果/官方文档
  > REVERSE_ANALYSIS.md 中带证据的当前结论
  > COMMANDER.md 顶部当前状态
  > 历史 Day 计划和旧对话
```

状态含义：

- ✅：证据闭环，可直接作为实现依据。
- 🟡：主体已确认，但仍有参数、分支或真机行为待验证。
- ⚠️：只有线索或合理推断，不能作为实现承诺。
- ❓：尚未开始或未定位。

---

## Prompt 1：通用审计任务

```text
你正在协助审计 Notability Android 的反编译结果，并为 HarmonyOS/OpenHarmony 目标端移植整理可执行结论。

开工前请完整阅读：
1. C:\Users\Cisco He\Desktop\Notability\COMMANDER.md
2. C:\Users\Cisco He\Desktop\Notability\REVERSE_ANALYSIS.md
3. C:\Users\Cisco He\Desktop\Notability\reports\README.md

本次任务：[填写一个边界明确的任务]

要求：
- 先检查知识库是否已有结论，再核对原始证据；不要机械重复已完成任务。
- “全局搜索没有结果”只能说明当前搜索范围未发现，不能单独证明功能未使用。
- 对 R8/ProGuard 合并类按具体构造器、方法或 switch 分支描述，不给整个混合类强行命名。
- 每条 ✅ 结论必须附文件+方法/行号、运行结果或官方链接；证据未闭环时标 🟡/⚠️。
- 区分“代码中存在”“业务路径实际调用”“平台公开支持”“真机性能已验证”四个层级。
- 不直接修改 COMMANDER.md 或 REVERSE_ANALYSIS.md；将结果写到独立报告：
  reports/YYYY-MM-DD-主题-执行者.md
- 报告包含：结论、证据链、仍不确定项、建议如何更新主文档。
```

---

## Prompt 2：反编译代码核验

```text
[先使用 Prompt 1 的通用要求]

任务：核验 [类/调用链/算法]，目标是判断当前 REVERSE_ANALYSIS.md 的描述是否准确。

请按以下顺序工作：
1. 从业务入口或已知调用者向下追踪，不以类名猜职责。
2. 同时检查构造器、字段写入、方法调用者和关键分支。
3. 对混淆类记录“文件 + 方法签名 + 分支条件 + 数据含义”。
4. 搜索不到调用时，继续检查反射、接口实现、协程/Compose lambda、native 声明和 R8 合并分支。
5. 输出最短闭环调用链，并标出 predicted/history/fallback 等旁路。
6. 若发现旧结论错误，明确写出：旧结论、反例、新结论、受影响章节。

不要仅给类名列表；最终报告必须能让汇总者据此修改主文档。
```

当前优先核验项：

- 创建/确认 HarmonyOS/ArkUI 工程骨架，并记录 DevEco、SDK/API level、目标 MatePad/系统版本和降级矩阵。
- 普通笔迹平滑容差的变量语义和各工具分支。
- `fc0.e()` 逐点宽度因子的生成来源、默认样式和压感映射。
- op 流顶层类型分发与页面增删结构。
- 图片具体元素类、裁剪/z-order，以及录音时间戳→`audioLinkedProgress` 的赋值链。
- UI 主题 token、字体/圆角/阴影、弹层锚点和动画参数；在 600/840/952/1400dp 临界宽度复核响应式重排。

---

## Prompt 3：HarmonyOS / OpenHarmony 官方 API 核验

```text
[先使用 Prompt 1 的通用要求]

任务：用华为官方文档核验 [API/能力]，不要用搜索摘要、论坛或营销稿替代正式参考。

报告至少记录：
- 完整 API 名称、包/import、函数签名。
- 起始版本、Stage/FA 模型限制、SystemCapability、权限和设备前提。
- 参数单位、取值范围；官方未给范围时明确写“未规定”，不要自行补数字。
- API 能做什么，以及它没有承诺什么。
- 与 Android 原能力是直接等价、近似替代还是仅可用于原型。
- 明确资料属于华为 HarmonyOS SDK 还是 OpenHarmony 上游；前者不能自动外推为后者的通用能力。
- 官方文档链接和查阅日期。

尤其不要把“存在预测点/帧加速 API”直接写成“端到端延迟必然 <16ms”；性能结论必须来自真机量测。
```

当前重点：Pen Kit、StylusFrameBoost、RenderNode、Canvas 2D/OffscreenCanvas、ArkGraphics 2D `ShaderEffect`、XComponent + EGL/OpenGL ES。

---

## Prompt 4：HarmonyOS 目标端 MVP 原型与真机测量

```text
[先使用 Prompt 1 的通用要求]

任务：实现一个最小可测原型，只验证 [输入/平滑/可变宽度/铅笔纹理/低延迟]。

开工闸门：
- 先定位目标 HarmonyOS 工程；若不存在，本任务的第一交付物就是可构建运行的 ArkUI/Hvigor 骨架。
- 报告 DevEco Studio、HarmonyOS SDK/API level、目标设备/系统版本、刷新率和所用能力的起始版本。
- 不得在未构建、未部署或未真机量测时宣称性能目标已达到。

原型要求：
- 原始点、历史点、预测点分开记录，预测点不得直接写入最终持久化笔画。
- 记录 eventTime、接收时间、提交绘制时间和可观测上屏时间；说明每个时间戳的时钟来源。
- 同一组轨迹至少对比：Canvas 2D、可用的 ArkGraphics 2D 路径；需要任意 shader/网格时再评估 XComponent + OpenGL ES。
- 铅笔使用 `ui_renderer__pencil_splat.png` + 程序化位置/旋转/缩放/透明度，不把纹理和散布算法混为一谈。
- 分别测平均值、P50、P95、最大值、掉帧和不同笔画长度；记录设备、系统版本、刷新率和是否连接手写笔。
- 先报告测量结果，不预设“2ms”或“<16ms”一定达成。

输出独立实验报告和可复现步骤；除非明确指定为汇总者，不修改两份主文档。
```

---

## Prompt 5：单一汇总者

```text
你是本轮唯一汇总者。请读取 PROJECT_HANDOVER.md、COMMANDER.md、REVERSE_ANALYSIS.md、reports/README.md 和指定的 reports/*.md。

任务：
1. 对报告中的证据做交叉检查，冲突时回到原始代码/官方文档。
2. 只把证据闭环内容升级为 ✅，其余使用 🟡/⚠️。
3. 更新 REVERSE_ANALYSIS.md 的技术结论和证据索引。
4. 更新 COMMANDER.md 的当前状态、阻塞项和下一步，不重写历史为“已确认”。
5. 做全文一致性检查，确认导航、正文、状态和术语一致。

同一时间只能有一个汇总者写 COMMANDER.md 与 REVERSE_ANALYSIS.md，避免并发覆盖。
```

---

## Prompt 6：UI 一比一移植核验

```text
[先使用 Prompt 1 的通用要求，并阅读 REVERSE_ANALYSIS.md 第 39 节]

任务：核验 [资料库/编辑器/菜单/面板] 的 UI 结构和视觉参数，为 HarmonyOS ArkUI 一比一实现输出可执行规格。

要求：
1. 从真实路由向下追踪：route → Composable → ViewModel → UiState → 子组件；不要只按截图猜组件层级。
2. 明确当前截图所处状态、选中项和 feature gate。注意 `notability_v14_home.png` 实际是 Notes 选中态，不是真正的 Home 内容。
3. 若模拟器在线，记录 `wm size`、`wm density`、rotation 和 UIAutomator bounds，把 px 换算为 dp；单设备结果不得冒充全设备规则。
4. 优先恢复代码中的响应式断点、固定 dp、状态分支和菜单锚点；截图只补颜色、间距和视觉结果。
5. 对每个参数标注来源：静态代码 / 运行时量测 / 截图估计 / 营销素材。后两者不能直接标 ✅。
6. 至少覆盖：页面树、主/内部导航归属、尺寸、点击热区、字体、颜色、圆角、描边/阴影、显隐条件、动画 duration/easing、Light/Dark。
7. HarmonyOS 规格使用 vp/fp 和响应式布局，不硬编码 1920×1080 像素；保留 600/840/952/1400dp（目标端对应 vp）断点语义，实机再校准。
8. 不移植 Frida 的 fake vmf/tmf/iof 或 reset hook；只移植 `o77/f89/zz8` 后的真实 UI 架构与状态模型。

输出：组件树、状态表、尺寸/token 表、证据链接、仍缺的动态量测和 ArkUI 页面拆分建议。
```

---

## 推荐使用方式

1. 每次只分配一个边界明确的问题。
2. 多个执行者可并行读代码，但各自写不同的 `reports/*.md`。
3. 报告命名、证据等级和职责边界以 `reports/README.md` 为准。
4. 等独立报告完成后，再由一个汇总者更新主文档。
5. 新任务从 COMMANDER.md 的“当前行动”选择；目标端尚无工程时，优先创建骨架并锁定平台矩阵，不要重新执行历史 Day 0 Prompt。
6. UI 任务优先使用 Prompt 6，并把截图视觉与反编译结构交叉验证。

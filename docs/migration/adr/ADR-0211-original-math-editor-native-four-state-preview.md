# ADR-0211：Math 编辑器必须由 Native 完整绘制驱动四态与预览

## 状态

Accepted，2026-08-15；由 Phase 235 / ADR-0212 补全 preview Density 像素契约。本文关闭 ADR-0124 中
“语法级 Invalid/Ok 与编辑器公式预览尚未完成”的边界。

## 问题

Harmony 已具备 LaTeX 修改事务和 Native Math 引擎，但编辑 overlay 仍只检查非空、UTF-8 round-trip 与
1 MiB 预算：任何满足静态门禁的字符串都能启用 Done，界面也没有显示原版公式 bitmap。这样会产生两类偏差：

1. 语法错误的 LaTeX 可以进入 durable MODIFY_BLOCK / CREATE_BLOCK 路径，直到后续画布渲染才暴露失败；
2. 用户编辑时看不到最终字体、缩放、裁切和主题颜色，无法像原版一样用预览确认公式。

异步初始化、快速连续输入、关闭 overlay、离开页面和主题切换还会产生迟到 bitmap；若不建立明确所有权，旧预览
可能覆盖新 draft，或者泄漏 `ImageBitmap` / `PixelMap`。

## 原版依据

- `v08` 把 preview 布局固定为 280dp×96dp；`axi.a()` 从 Compose Density 取得 `r93`，调用
  `j0(280)` / `j0(96)` 转成物理像素后才交给 Native render。`r93.j0(f)` 明确返回 `density × f`。
- `w08.invokeSuspend()` 对空白 draft 发布 `lwa(Empty)`；非空先发布 `nwa(Loading)`，然后在 `s18.f()` 中执行
  `p18` 的完整 Native measure/draw。结果为 null 时发布 `mwa(Invalid)`，bitmap 成功时发布 `owa(Ok)`。
- `p18.invoke()` 对已经完成 Density 转换的宽高再以 1.0 scale 创建完整目标 bitmap，调用 `s18.d()` 做框内 fit，并把主题文字色交给
  `GLMathNative.nativeDraw()`；任何 measure、尺寸或 draw 失败都回收 bitmap 并返回 null。
- `v08` 的 96-high preview 区只为 `owa` 显示 bitmap，只为 `mwa` 显示 invalid 文案；Empty 与 Loading 不伪造
  预览。Done 的 enabled 参数严格等于当前状态是否为 `owa`。
- `n07` 的 Done 回调读取当前 draft 并启动异步 durable 提交；外层提交失败提示与语法 Invalid 是不同状态。

## 决策

1. 编辑器状态显式建模为 `EMPTY / LOADING / INVALID / OK`，不能再用一个静态 `isValid` 布尔值替代。
2. 空白 draft 立即进入 Empty；UTF-8 round-trip 或 1 MiB 预算失败立即进入 Invalid；其余 draft 进入 Loading。
3. 只有 `OriginalMathEngine` 已就绪时才执行完整 render。布局仍是 280vp×96vp，但必须先用当前 ArkUI Density
   转成物理像素，再保持原版独立的 `pixelScale=1`；不能把 raw 280×96 像素拉伸到高密度布局，也不能同时
   转换宽高和放大 pixelScale。引擎仍在初始化时保持 Loading；初始化完成后自动续验。初始化已结束但引擎
   不可用时 fail closed 为 Invalid。
4. Native render 返回 null 或抛出异常时进入 Invalid；只有同时持有本次 draft 的完整 bitmap 才进入 Ok。
5. preview 区固定 96 unit 高，panel 内容宽度不超过原版 280 unit；仅 Ok 显示 bitmap，仅 Invalid 显示语法提示。
   durable 提交失败文案保持独立，不能把数据库/事务失败伪装成语法错误。
6. Done 只在 `state === OK && !busy` 时启用；确认处理器再次要求当前 Ok preview，避免 UI 门禁与异步状态之间的
   竞态绕过。
7. 每次 draft、主题、visible 或 lifecycle 变化都递增 validation generation，并校验 generation、draft、visible
   与 active 状态后才安装结果。迟到 bitmap 必须立即释放，不能覆盖新一代状态。
8. 替换预览、Cancel、提交成功和页面离开时同时关闭 `ImageBitmap` 并释放 `PixelMap`；主题改变时按当前
   `textPrimary` ARGB 重新绘制。

## 结果

- 编辑器的语法成功现在等价于“当前 draft 已由生产 Native 引擎完整绘制”，而不是字符串看起来非空。
- 用户在提交前看到与画布共用引擎、框适配和主题颜色的公式预览。
- 快速输入、初始化完成、主题切换、Cancel 与页面 lifecycle 不会让旧 bitmap 回写或遗留 Native 图像资源。
- MODIFY_BLOCK / CREATE_BLOCK 的 durable 事务、失败保留 draft、Undo/Redo 与编辑时几何不变契约保持不变。

## 边界

- Harmony 已恢复逻辑框到物理像素的 Density 转换；Native Drawing 与 Android Canvas 的字体 fallback、hinting
  和抗锯齿仍可能产生平台像素差异。
- Loading 当前不显示额外 spinner，与原版反编译结果一致地保持 preview 区空白；真机仍需确认等待感受。
- 设备上的输入法 composing、多窗口 lifecycle、深浅主题即时切换和超长/极端 LaTeX 仍需交互与内存验收。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium。

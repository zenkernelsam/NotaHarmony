# Phase 841 — `core/` 包叶子面闭合

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/core/` 全叶子

## 一、类型化异常族（另一组失败分类学）

| 类 | 语义 |
|----|------|
| `core/network/HttpStatusException` | HTTP 状态码异常 |
| `core/network/NoConnectivityException` | 无连接 |
| `core/network/NotAuthenticatedException` | 401 未认证 |
| `core/retrofit/HttpFailureException` | Retrofit 失败 |
| `core/analytics/NbPerformance$SpanAborted` | 埋点 span 中止 |
| `core/common/logging/NbLog$FatalLogError` | fatal 日志载体 |
| `core/common/logging/FirebaseLogger$LoggedError` | Firebase 日志异常 |
| `core/common/memory/SharedMemoryByteArena$ArenaClosedException` | 共享内存 arena 关闭异常 |
| `core/model/CopyPasteException` | 复制粘贴失败 |

## 二、`core/common/memory` —— 共享内存 arena

`SharedMemoryByteArena` + `ArenaClosedException`：**原生墨水
缓冲的共享内存区**（ink stroke 跨层共享，大 buffer 避免复制）。

## 三、`core/glmath` —— libglmath 本地数学引擎（重要）

`GLMathNative`（`System.loadLibrary("glmath")`）四个 JNI：

| native | 签名 | 语义 |
|--------|------|------|
| `nativeInit` | `(resPath)→bool` | 数学资源初始化 |
| `nativeMeasure` | `(latex,width,fontSize)→float[]` | LaTeX 测量 |
| `nativeDraw` | `(latex,w,h,fontSize,argbColor,MathDrawTarget)→bool` | LaTeX→本地绘制 |
| `nativeSearchText` | `(latex)→byte[]` | 数学可搜索文本提取 |

`MathDrawTarget`（97 行）= 绘制接收端接口；`GLMathTextMeasurer`
= 测量门面。

**Harmony 侧**：`MathEditorOverlay` 用 `image.PixelMap` 预览——
**预渲染位图而非实时 LaTeX 排版引擎**。差异登记（native
排版不可移植；Harmony 侧走位图化路径）。

## 四、其余 `core/` 包

- `analytics/`、`logging/`、`network/`、`retrofit/`、`user/`
  （UserDataStoreInitializer=819 确认）、`model/`（snapshot/）、
  `glmath/` 全部归位。

## 五、结论

`core/` 包闭合：网络/日志/埋点/内存/复制粘贴类型化异常族
+ 共享内存 arena + libglmath 本地数学引擎（4 JNI 面固化）。
`**_` 例外类=类型化恢复信号，与 840 同步失败族同类
设计模式——原版错误面重度类型化。

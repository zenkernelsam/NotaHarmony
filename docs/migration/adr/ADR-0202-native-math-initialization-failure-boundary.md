# ADR-0202：Native Math 初始化必须事务式失败关闭并缓存失败结果

## 状态

Accepted，2026-08-15。

## 问题

Harmony `Initialize()` 直接调用 `tex::LaTeX::init(root)`，没有任何 C++ 异常边界。即使 ArkTS
`OriginalMathEngine.prepare()` 外层有 `try/catch`，C++ 异常也不能安全地穿过 N-API callback 再被 JavaScript
捕获；损坏的缓存资源、字体 XML 解析错误或第三方初始化异常可能直接终止 native 进程。

当前状态提交也不是事务式的：初始化返回后无条件写入 `gInitialized = true`，但最终又以资源根是否为空决定返回值，
可能形成“内部标记已初始化、公开结果却为 false”的矛盾状态。若异常发生在 MicroTeX 部分全局对象建立之后，盲目重试
还可能把半初始化状态当作成功状态继续使用。

N-API 环境 cleanup hook 同样直接调用 `LaTeX::release()`；任何释放异常越过 cleanup callback 都可能在进程退出或
环境销毁期间触发终止。

## 原版证据

- `GLMathNative.nativeInit(String)` 的公开契约是 boolean。
- 原版 arm64 `nativeInit @ 0x2217e8` 在 `LaTeX::init` 抛出 TeX 异常时进入 catch：
  - `__cxa_begin_catch @ 0x221944`；
  - `mov w19, wzr @ 0x22194c`；
  - 最终以 `w0 = 0` 返回 false，而不是让异常穿过 JNI。
- `s18.b()` 还在 Java/Kotlin 层捕获 native 调用的 `Throwable`，把普通初始化故障降级为 `Boolean.FALSE`。
- `s18.c` 缓存 Boolean；一旦得到 true 或 false，后续调用直接返回同一结果，不会在同一 renderer 生命周期中反复
  初始化可能已经部分建立的 native 全局状态。
- 原版在 false 路径记录资源提取/引擎初始化失败，公式功能降级不可用，但 App 继续运行。

## 决策

1. 新增 `gInitializationAttempted`，区分“从未尝试”与“尝试失败”。
2. 参数类型或空路径错误在尝试门之外拒绝，不消耗唯一一次有效初始化机会。
3. 第一次有效调用在进入第三方代码前先把 attempted 设为 true，防止异常后的隐式重入或危险重试。
4. `LaTeX::init()`、解析后的资源根读取和字符串提交位于同一 try 块；只有全部成功且资源根非空，才同时提交
   `gResourceRoot` 与 `gInitialized = true`。
5. `std::exception` 与未知异常都在 Native callback 内收敛为 false，清空公开状态，禁止跨越 N-API。
6. 失败结果在当前 N-API 环境生命周期内缓存；后续 Initialize 只返回 false，不再调用 MicroTeX init。
7. `napi_get_boolean()` 的状态和结果指针必须检查，避免使用未初始化的 `napi_value`。
8. cleanup hook 用 catch-all 包围 `LaTeX::release()`；无论释放结果如何，都清空 initialized、attempted 与资源根状态。

## 结果

- 损坏 Math 资源或第三方初始化异常只会让公式引擎 unavailable，不再击穿 native 进程。
- 初始化状态只在完整成功后一次性提交，不会出现 true/false 矛盾状态。
- 失败后的重复初始化调用稳定返回 false，匹配原版 `s18` 的结果缓存，也避免使用半初始化 MicroTeX 全局对象。
- N-API 环境清理路径不再传播 C++ 异常。
- cleanup 完成后会重置尝试门，若宿主建立新的环境生命周期，可从干净的 wrapper 状态重新初始化。

## 边界

- 当前环境内初始化失败后不会自动重试；这与原版一致，也意味着修复资源后需重启应用/重建 N-API 环境。
- 若第三方初始化在抛错前已经建立部分内部全局对象，本层不会调用可能同样不安全的部分 `release()`；它们随进程结束
  回收。此取舍优先保证失败路径不二次崩溃。
- 桌面 replay 能证明状态机与异常边界，不能真正注入设备端字体解析、native OOM 或 cleanup 异常；仍需真机故障注入。

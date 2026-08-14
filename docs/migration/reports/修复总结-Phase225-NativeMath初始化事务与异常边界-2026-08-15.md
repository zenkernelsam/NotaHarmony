# Phase 225 修复总结：Native Math 初始化事务与异常边界

## 发现

Phase 224 修复默认颜色后，继续反汇编原版三个 JNI 入口，确认 Harmony `Initialize()` 仍缺少原版已有的失败边界：

- `tex::LaTeX::init(root)` 抛出的 C++ 异常会直接越过 N-API callback；ArkTS 外层 `try/catch` 不能保证接住这种
  native 异常，进程可能终止。
- 初始化返回后无条件写 `gInitialized = true`，但返回 boolean 又依赖资源根非空，存在状态与公开结果矛盾。
- 初始化失败后没有 attempted 状态，调用方会反复进入可能已经部分初始化的 MicroTeX 全局对象。
- cleanup hook 直接调用 `LaTeX::release()`，释放异常也可能穿过宿主清理边界。

## 原版依据

- `GLMathNative.nativeInit` 返回 boolean。
- 原版 arm64 `nativeInit @ 0x2217e8` 捕获 TeX 初始化异常：在 `0x221944` 进入 catch，并于 `0x22194c`
  把返回寄存器状态设为 0，最终返回 false。
- `s18.b()` 外层继续捕获 `Throwable`，将普通 GLMath 初始化错误降级为 `Boolean.FALSE`。
- `s18.c` 缓存初始化结果；成功和失败都只求值一次，同一 renderer 生命周期不会反复重试 native init。
- 原版失败后记录引擎不可用，公式功能降级，但不让普通资源故障击穿 App。

## 修复

- 新增 `gInitializationAttempted`，建立“未尝试 / 已失败 / 已成功”三态语义。
- 无效 N-API 参数在尝试门之前拒绝，不浪费有效初始化机会。
- 首次有效调用在进入 MicroTeX 前先提交 attempted，随后在 try 内完成：
  - `LaTeX::init(root)`；
  - 读取实际资源根；
  - 验证非空；
  - 一次性提交资源根和 initialized。
- 标准异常与未知异常均在 native callback 内收敛，清空公开状态并返回 false。
- 失败结果在当前 N-API 环境内缓存，不对潜在半初始化状态进行第二次 init。
- `napi_get_boolean()` 改为初始化空指针并检查状态。
- cleanup hook 对 `LaTeX::release()` 使用 catch-all，随后无条件清空 initialized、attempted 与资源根 wrapper 状态。
- 新增 `d02-native-math-initialization-failure-boundary.mjs`，锁定原版 boolean/Throwable/结果缓存证据、
  Harmony 事务提交、双异常边界、单次尝试与 cleanup 重置。
- 新增 `ADR-0202-native-math-initialization-failure-boundary.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-initialization-failure-boundary.mjs`
- `docs/migration/adr/ADR-0202-native-math-initialization-failure-boundary.md`
- `docs/migration/reports/修复总结-Phase225-NativeMath初始化事务与异常边界-2026-08-15.md`

## 验证

- 初始化失败边界专项 replay：`TOTAL=16 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=16 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=212 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 562 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 785 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 在已存在 `.complete` 的资源目录中损坏一个 font XML，确认启动不崩溃、Math 引擎返回 unavailable。
- 同一运行期多次触发 initialize，确认第一次失败后稳定返回 false，且不会出现二次 native 崩溃或部分公式可用。
- 正常资源下确认首次 initialize 为 true，后续调用复用状态且公式测量/渲染不回归。
- 退出 Ability、销毁 N-API 环境并重新进入，确认 cleanup 后新环境可以重新初始化。
- 通过故障注入让 release 抛错，确认环境清理仍完成且进程不因异常跨 callback 终止。

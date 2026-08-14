# ADR-0203：Native Math 的 N-API 参数与结果构造必须逐步验证

## 状态

Accepted，2026-08-15。

## 问题

Native Math 已保护 Bitmap、Canvas、Pen/Brush 与 ArrayBuffer 的主要分配，但 N-API callback 自身仍假定宿主操作必定
成功：

- `napi_get_cb_info()` 失败后仍继续读取 arguments；
- `napi_create_object()`、`napi_create_double()`、`napi_get_boolean()`、`napi_create_string_utf8()` 和
  `napi_set_named_property()` 的状态全部被忽略；
- 多处 `napi_value result;` 未初始化，创建失败后仍会作为对象或返回值使用；
- ErrorResult 自己也依赖未检查的对象与字段构造，因此无法作为 N-API 分配失败时的可靠兜底；
- 模块属性定义与 cleanup hook 注册失败仍返回看似成功的 exports；
- 输入字符串的本地 `std::string::resize()` 分配发生在 callback 的 try/catch 之外。

在内存压力、pending exception 或宿主 N-API 故障下，这些路径可能把本应失败关闭的单次公式操作升级为空句柄访问、
未定义返回值或 native 崩溃。

## 原版证据

- 原版 `s18` 把 `nativeMeasure()` 的 null 视为普通公式失败，不继续读取结果数组。
- 原版 arm64 `nativeMeasure @ 0x221990` 创建四字段 float array 后立即检查返回值：
  `cbz x0 @ 0x221a44`；分配失败时跳过数组写入并返回 null。
- 原版 `nativeDraw @ 0x221bc8` 在绘图回调结束后调用 JNI `ExceptionCheck`；若 Java 绘图发生 pending exception，
  会清除异常并返回 false，而不是报告成功。
- `p18` 收到 nativeDraw false 后 recycle 临时 Bitmap 并返回 null。
- Harmony ArkTS 的 Measure/Render consumer 已能把 native null/失败结果降级为公式不可用，因此 callback 直接失败
  比继续组装不完整对象更符合原版体验。

## 决策

1. `ReadString()` 的本地字符串分配放入 catch-all；分配失败清空结果并返回 false。
2. `SetNumber`、`SetBoolean`、`SetString` 全部返回 bool：
   - 初始化 `napi_value` 为 null；
   - 检查值创建/获取状态；
   - 检查句柄非空；
   - 检查 named property 写入状态。
3. ErrorResult 必须验证 result object、`valid` 与 `error` 两个字段；任一步失败直接返回 null。
4. Initialize、Measure、Render 首先检查 `napi_get_cb_info()`；失败时不访问 arguments，也不尝试构造第二个错误对象。
5. Measure 成功结果的 object、valid、width、height、baseline、depth 必须全部写入成功才返回。
6. Render 成功结果的 object、valid、width、height、pixels 必须全部写入成功才返回。
7. 结果构造失败沿 C++ 作用域退出，现有 TeXRender、HarmonyGraphics、Canvas 与 Bitmap 所有者按逆序自动回收。
8. ArrayBuffer 仍必须在 memcpy 前验证状态、destination 与 value；后续 pixels property 写入也必须检查。
9. 模块 exports 属性定义与 cleanup hook 注册均检查 `napi_status`，任一步失败时模块 init 返回 null。
10. 禁止在 Native Math 中保留未初始化的 `napi_value result`。

## 结果

- N-API 对象或字段分配失败后不再继续使用空/未初始化句柄。
- ErrorResult 在可构造时仍提供结构化失败；当宿主已有 pending exception 或连错误对象也无法分配时，直接返回 null。
- Measure/Render 不会把缺字段的半成品对象交给 ArkTS。
- 结果构造失败仍保证 native 绘图资源按作用域回收。
- callback 参数提取失败和本地输入字符串 OOM 均在第三方解析前停止。
- 模块不会在 cleanup hook 未注册时伪装为完整初始化成功。

## 边界

- 返回 null 时具体 JavaScript 异常由 N-API 宿主状态决定；本层保证的是不再继续触碰无效句柄。
- 桌面 replay 无法直接强制设备 N-API 每个函数返回 OOM/pending exception，仍需 native 故障注入验证。
- 本决策只收口 `libnota_math.so`；其他 native 模块的 N-API 状态检查需按各自任务继续审计。

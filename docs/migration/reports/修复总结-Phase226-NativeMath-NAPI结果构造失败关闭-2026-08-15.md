# Phase 226 修复总结：Native Math N-API 结果构造失败关闭

## 发现

Phase 225 收口初始化异常后，继续完整反汇编原版 `nativeMeasure/nativeDraw`，发现 Harmony 仍只保护了主要绘图对象，
没有保护 N-API callback 自身的结果构造：

- callback 不检查 `napi_get_cb_info`；
- result object、number、boolean、string 和 named property 的所有状态均被忽略；
- 多处 `napi_value result` 未初始化，创建失败后仍继续使用；
- ErrorResult 本身也可能在对象创建失败后触碰无效句柄；
- Measure/Render 可能把缺字段的半成品成功对象交给 ArkTS；
- 模块 exports 或 cleanup hook 注册失败仍返回成功；
- `ReadString` 的本地分配异常发生在 callback 异常边界之外。

## 原版依据

- `s18` 对 `nativeMeasure()` null 明确返回公式失败，不读取不存在的度量数组。
- 原版 arm64 `nativeMeasure @ 0x221990` 在创建 float[4] 后以 `cbz x0 @ 0x221a44` 检查分配结果；null
  时跳过数组写入并返回 null。
- 原版 `nativeDraw @ 0x221bc8` 在绘图后检查 JNI pending exception；存在异常时清除并返回 false。
- `p18` 收到 false 后 recycle 临时 Bitmap，随后返回 null，不保留失败绘图。
- Harmony ArkTS 已将 native false/null 或 `valid:false` 收敛为公式不可用，适合保持原版失败降级语义。

## 修复

- `ReadString` 的 resize/copy/resize 放入 catch-all，本地分配异常清空并返回 false。
- `SetNumber`、`SetBoolean`、`SetString` 改为 bool helper：
  - 所有 `napi_value` 从 null 初始化；
  - 检查 value 创建/获取；
  - 检查句柄非空；
  - 检查 property 写入。
- ErrorResult 只有在 result object、valid=false 与 error 全部构造成功时才返回对象，否则返回 null。
- Initialize、Measure、Render 全部先检查 `napi_get_cb_info`。
- Measure 的 object、valid、width、height、baseline、depth 改为全字段提交门。
- Render 的 object、valid、width、height、pixels 改为全字段提交门；pixels named property 也检查状态。
- 结果提交失败直接退出 callback，现有 TeXRender、Graphics、Canvas、Bitmap 继续按作用域逆序回收。
- 模块 `napi_define_properties` 与 `napi_add_env_cleanup_hook` 均检查状态。
- 删除 Native Math 中全部未初始化 `napi_value result` 声明。
- 新增 `d02-native-math-napi-result-safety.mjs`，锁定原版 null/false 降级证据、callback 参数门、字段 helper、
  错误结果、成功结果、pixels 属性、模块注册以及短路模型。
- 新增 `ADR-0203-native-math-napi-result-construction-safety.md`。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-napi-result-safety.mjs`
- `docs/migration/adr/ADR-0203-native-math-napi-result-construction-safety.md`
- `docs/migration/reports/修复总结-Phase226-NativeMath-NAPI结果构造失败关闭-2026-08-15.md`

## 验证

- N-API result safety 专项 replay：`TOTAL=16 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=17 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=213 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 108 ms`。
- `note@ohosTest assembleHap`：通过，`BUILD SUCCESSFUL in 1 s 787 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 对 N-API create object/string/ArrayBuffer 与 property set 注入失败，确认 callback 返回异常/null 而不是 native 崩溃。
- 在 Measure 的 width/height/baseline/depth 任一字段写入失败时，确认 ArkTS 不会收到缺字段的 valid=true 对象。
- 在 Render 的 pixels property 写入失败时，确认 Bitmap/Canvas/Pen/Brush 与临时 ArrayBuffer 可被回收。
- 连续大公式制造内存压力，确认 ErrorResult 无法分配时仍不会继续触碰空句柄。
- 模块 cleanup hook 注册故障注入下确认 `libnota_math.so` 不被误判为完整可用。

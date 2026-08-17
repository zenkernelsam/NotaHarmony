# ADR-0245：CFBinaryPlist 规范结构门禁与失败契约

## 状态

Accepted - Phase 267（2026-08-17）

## 背景

Android 原版 1.0.3 没有读取旧 iPad `.note` 中 CFBinaryPlist/NSKeyedArchiver 的实现，因此本项不能伪造原版
逐行移植。权威依据依次为 Apple `CFBinaryPList.c`、仓库内真实 `OP-AMP.note` 样本，以及 Harmony 导入侧
“损坏数据不得被包装成成功”的明确平台契约。

早期 M2-F-01 与 Phase 163/174 已补齐对象区上界、资源预算、严格字符串、循环引用拒绝和 URL base 引用校验，
但现场重放仍发现以下分叉：

- offset table 只要求位于 trailer 前，没有要求其末尾与 trailer 精确相接；
- `objectRefSize` 与 `offsetIntSize` 没有验证是否足以表达 trailer 声明的对象数和偏移表位置；
- 被 offset table 或容器引用的 fill `0x0F` 被转换为 plist null；
- ordered-set `0xB` 被并入 ARRAY，丢失原类型并接受了 `bplist00` 参考解析器不发布的 marker；
- 重复字典键由 Harmony `dictGet()` 采用 first-wins，而 Apple 参考实现会由后值覆盖前值；
- ArkTS fixture 与累计进展仍保留“循环 warning + null”的 Phase 163 前旧口径。

## 决策

### Trailer 与 offset table

- 对象区至少包含 header 后一个字节，故 `offsetTableOffset` 必须大于 8。
- `numObjects * offsetIntSize` 计算出的 offset table 必须精确结束于 32-byte trailer 起点；中间任何 gap 或
  额外字节均视为非规范结构并拒绝。
- `objectRefSize` 必须满足 `256^size > numObjects`，`offsetIntSize` 必须满足
  `256^size > offsetTableOffset`。这与 Apple 参考实现的严格不等式一致；256 个对象不能宣称一字节引用。
- 7/8 字节宽度的容量已超过 JavaScript 安全整数范围；在 trailer 的 64 位字段已先通过安全整数门后，helper
  可直接接受这两种宽度。

### Marker 与对象图

- fill `0x0F` 只允许作为对象区填充字节；一旦 offset table 或对象引用指向它，整份 plist 失败，不能变成 null。
- `0xB` 在格式注释中是 v1? ordered-set，但 Apple 当前 v00 解析分支只发布 ARRAY/SET。Harmony 值模型也没有
  ordered-set 联合，因此显式报错，不得静默降级成 ARRAY。
- 容器循环继续沿用 Phase 163 的 hard failure：写入 parser error，根值不发布，warning 列表不生成 null 占位。

### 重复字典键

- BinaryPlist 解析阶段按解码后的字符串值检查重复键，发现重复即拒绝整份 plist。
- `NSKeyedArchiverDecoder` 在完整值图预检中独立执行同一门禁。这样即使测试、未来 XML plist 或其他构造路径
  直接生成 `PlistValue`，也不能绕过 archive 层。
- Apple 源码把 hash-equal 重复键称为 malformed，但其容器写入行为会形成 last-wins；旧 Harmony
  `dictGet()` 是 first-wins。选择整体拒绝可消除同一恶意归档在两种解析器中产生不同业务字段的风险。

## 后果

- 合法真实样本不受影响，其 offset table 均精确衔接 trailer，且宽度足以表达声明值。
- trailer gap、过窄 ref/offset、被引用 fill、ordered-set、重复键和循环引用全部在 decoder 发布业务对象前
  fail closed，不再产生静默类型转换或 winner-order 分叉。
- 对未来真正需要 ordered-set 的格式版本，必须先扩展 `PlistType`、顺序语义、上层 consumer 与 fixture；不能
  仅把 marker 并入数组分支。

## 验证契约

- `BinaryPlistParser.test.ets` 覆盖 trailer gap、256 objects/1-byte ref、offset table 超过 255/1-byte offset、
  fill、ordered-set、重复键和循环 hard failure。
- `NSKeyedArchiverDecoder.test.ets` 覆盖直接构造的重复 plist 字典，证明 archive 层独立拒绝。
- `d02-cfbinaryplist-canonical-structure.mjs` 重放三份 tracked plist 的 trailer identity，并构造 hostile fixture。
- 保留 `d02-binary-plist-cycle-rejection.mjs` 与 URL base 引用 replay，防止本阶段回退 Phase 163/174。

## 边界

- 本阶段只证明静态解析、fixture 编译和桌面 replay；未启动设备、模拟器、虚拟机、真机或 Hypium。
- Android 原版没有该导入器，故不把 Apple/Harmony 的 fail-closed 决策冒充 Android 原版行为。
- 新格式版本、XML plist、真实含 ordered-set 的样本和端到端用户错误提示仍需独立证据与验收。

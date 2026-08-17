# Phase 267 修复总结：CFBinaryPlist 规范结构门禁与失败契约

## 基线与目标

- 基线提交：`4cac2ca docs: HarmonyOS 模拟器操作指南（启动/恢复/部署）+ abiFilters 增加 x86_64`
- `c1be5f0` 是该提交的直接祖先；Phase 264～266 的成果保持完整，本阶段没有 reset/rebase/revert 用户并发提交。
- 目标：重放 M2-F-01/02 的 BinaryPlist/KeyedArchive 现场，按 Apple CFBinaryPlist 与 tracked OP-AMP 样本
  收紧 trailer、offset/ref、marker、循环和重复字典键的失败契约。
- 本阶段不启动设备、模拟器、虚拟机、真机或 Hypium。

## 权威基准

Android 原版 1.0.3 没有旧 iPad `.note` 的 CFBinaryPlist/NSKeyedArchiver 导入代码，因此不能把本阶段冒充为
Android 原版逐行移植。格式层权威为：

1. Apple `CFBinaryPList.c`，commit `dc54c6bb1c1e5e0b9486c1d26dd5bef110b20bf3`；
2. 仓库内 tracked `test_notes/OP-AMP.note` 与三份解包 plist；
3. Harmony 导入侧明确的 fail-closed 平台适配：损坏或歧义结构不能发布部分业务对象。

Apple 文件 SHA-256、关键行、样本哈希和 trailer 公式见
`docs/migration/evidence/apple-cfbinaryplist-canonical-structure-2026-08-17.md`。

## 修复前真实缺陷

### Offset table 没有规范闭合

旧 parser 只要求 offset table 区域不越过 trailer，但允许 table 与 trailer 之间存在任意 gap；同时没有验证
`objectRefSize` 是否能表达对象数、`offsetIntSize` 是否能表达 offset table 起点。恶意 trailer 可以声明过窄宽度，
使同一字节流在不同实现中产生截断或不同解释。

### Marker 被静默改义

- 被 offset table 或容器引用的 fill `0x0F` 会变成 plist null；
- `0xB` ordered-set 与 ARRAY/SET 共用分支，最终被降级为 ARRAY。

Apple v00 实际对象创建分支不会发布 ordered-set，fill 也不是可引用 plist value；旧行为会把损坏/新版本数据
包装成看似合法的旧模型。

### 重复键存在 first/last-wins 分叉

Apple 参考实现明确称 hash-equal duplicate keys 为 malformed，但容器写入会让后值覆盖前值。Harmony
`PlistValue.dictGet()` 从前向后返回第一个值。继续接受重复键会让同一归档在两侧选择不同 `$objects`、`$top`、
metadata 或业务字段。

### 文档和 fixture 回退了 Phase 163

生产 parser 自 Phase 163 起已把循环引用作为 hard error，但 `BinaryPlistParser.test.ets` 和累计进展仍期待
“warning + null”。这会使后续维护者误以为不完整对象图仍是合法容错。

## 实际修改

### BinaryPlist trailer 与宽度门禁

- 新增共享宽度判定：`256^size > value`；7/8 字节在安全整数前置门后直接满足容量。
- `offsetTableOffset` 必须大于 8，保证对象区至少一个字节。
- `offsetTableOffset + numObjects * offsetIntSize` 必须精确等于 trailer 起点。
- hostile fixture 覆盖 trailer gap、256 objects/1-byte ref、table offset 256+/1-byte offset。

### 对象图 fail closed

- 被引用 fill 明确设置 parser error，不再返回 null value。
- `0xB` 明确报“不受支持”，不得降级 ARRAY；未来支持 ordered-set 必须先扩展值模型与 consumer。
- 循环继续整份失败；ArkTS 测试改为断言 null root + error，warnings 为空。

### 重复字典键双层拒绝

- BinaryPlist parser 在构造字典前按解码字符串检查重复 key。
- `NSKeyedArchiverDecoder.validateValue()` 独立检查完整值图，防止直接构造 `PlistValue`、未来 XML plist 或
  其他入口绕过 parser 门。
- 不选择 first-wins 或 last-wins，消除跨解析器 winner-order 分叉。

### 边修边补审

- 撤销域3旧审计“把 ordered-set 并入 ARRAY”的错误指令，并更正 `0x0C/0x0D/0x0E` 的 URL/UUID 语义。
- 更正 F-22、M2-F-01 与累计进展中仍写着“循环 warning + null”的过时现场。
- 两份修复总纲和累计进展均补录 Phase 267；T-042 继续保留到整个 Goal 最后。

## Tracked 样本结果

| 样本 | 长度 | offset/ref | objects/table | 闭合结果 |
|---|---:|---|---|---|
| `Session.plist` | 558797 | 4/2 | 308 / 557533 | `557533 + 308×4 = 558765 = length-32` |
| `metadata.plist` | 955 | 2/1 | 97 / 729 | `729 + 97×2 = 923 = length-32` |
| `HandwritingIndex/index.plist` | 10271 | 2/1 | 161 / 9917 | `9917 + 161×2 = 10239 = length-32` |

三份 tracked plist 均满足新门禁，没有把真实 OP-AMP 样本误拒。

## 修改范围

- 生产：`BinaryPlistParser.ets`、`NSKeyedArchiverDecoder.ets`
- ArkTS fixture：`BinaryPlistParser.test.ets`、`NSKeyedArchiverDecoder.test.ets`
- Replay：`d02-cfbinaryplist-canonical-structure.mjs`
- 文档：ADR-0245、Apple CFBinaryPlist evidence、域3审计更正、两份总纲、累计进展与本中文 Report

## Replay 与构建验证

- 新专项：`TOTAL=18 FAILED=0`
- CFBinaryPlist 相关 3 个 replay：`RELATED_REPLAY_FILES=3 ASSERTIONS=27 FAILED=0`
- 全量桌面 replay：`REPLAY_FILES=252 FAILED=0`
- 增量 `note@ohosTest`：`BUILD SUCCESSFUL in 14 s 654 ms`
- 同一次 clean 后严格串行终验：
  - clean：`BUILD SUCCESSFUL in 2 s 596 ms`
  - `note@ohosTest`：`BUILD SUCCESSFUL in 9 s 478 ms`
  - `note@default`：`BUILD SUCCESSFUL in 53 s 901 ms`
- 构建只有项目既有 ArkTS/deprecation warning 和未配置 signing 的 warning；没有新增 error。
- `ohosTest` 只证明 fixture 已完成 ArkTS 编译/打包，不冒充设备执行 Hypium assertion。

## 当前结论与剩余边界

M2-F-01 中已知的 canonical trailer、ref/offset capacity、fill、ordered-set、重复键和循环失败契约已收口；
M2-F-02 的 archive 重复键遮蔽也已封闭。仍需开放：

- XML plist 或未来 binary plist 版本的独立格式入口；
- 有真实格式版本证据的 ordered-set 值模型与 consumer；
- 更多来源/版本的 `.note` 样本、模糊测试与端到端用户错误提示；
- 设备上的实际文件选择、导入进度、失败提示和大包内存峰值。

## Goal 纪律

T-042 APK 版本追踪继续严格留到整个 Goal 最后。本阶段不创建版本追踪目录、不执行新版 APK 全量 diff；最终必须
另写中文 Report，并把追踪文档/工具的用途、入口、阅读顺序和新版 APK decompile/diff 流程纳入 Wiki、技术/API
文档与新手入门。

# Apple CFBinaryPlist 规范结构证据（2026-08-17）

## 证据边界

Android 原版 1.0.3 的反编译源码/resources 中没有 `bplist`、`CFBinaryPlist`、`NSKeyedArchiver` 或
`Session.plist` 解析入口。`.note` 的 CFBinaryPlist 导入是 Harmony 移植侧新增能力，因此本证据不宣称来自
Android 原版实现；格式层以 Apple CoreFoundation 参考源码与真实归档字节为权威，上层恢复语义才继续参考
Notability 内容模型。

## Apple 源码身份

- 上游：`https://github.com/apple-oss-distributions/CF.git`
- commit：`dc54c6bb1c1e5e0b9486c1d26dd5bef110b20bf3`
- commit subject：`CF-1153.18`
- commit date：`2021-10-06T04:41:50Z`
- 文件：`CFBinaryPList.c`
- 文件长度：71742 bytes
- SHA-256：`F3478DB429D8DDD674C96B153FD565E98A06B4EFCC8701B395B84CA881A56695`
- 本轮只读临时 clone：
  `C:\Users\Cisco He\AppData\Local\Temp\codex-cf-946ce9879eba4629a6382aa482755e5f`

临时 clone 仅用于核验；可复现身份是上游 URL、commit 与文件 SHA-256，不依赖临时目录长期存在。

## 1. Marker 表与 v00 实际发布类型

`CFBinaryPList.c:247-267` 的格式注释列出：

- `0x0F` 是 fill byte；
- `0xA` 是 array；
- `0xB` 是带 `[v"1?"+ only]` 注记的 ordered set；
- `0xC` 是同样带版本注记的 set；
- `0xD` 是 dict。

但真正的对象创建 switch 在 `1299-1300` 只进入 `kCFBinaryPlistMarkerArray` 和
`kCFBinaryPlistMarkerSet`，`1390-1425` 也只发布 CFArray 或 CFSet，没有 ordered-set 分支。因此对
`bplist00` 把 `0xB` 静默映射成 ARRAY 会改变类型含义；Phase 267 选择显式拒绝，直到值模型和格式版本都有
独立证据。

## 2. 对象区、offset table 与 trailer 必须精确闭合

`CFBinaryPList.c:782-822` 给出 trailer 结构门：

- 至少一个对象；top object 必须小于对象数；
- `offsetTableOffset >= 9`，即 `bplist??` 后至少一个对象字节；
- offset/ref 宽度至少一字节；
- offset table 大小为 `numObjects * offsetIntSize`，乘加必须不溢出；
- `datalen` 必须精确等于 header + object data + offset table + trailer；
- 当宽度小于 8 时，`2^(8*objectRefSize) <= numObjects` 为非法；
- 当宽度小于 8 时，`2^(8*offsetIntSize) <= offsetTableOffset` 为非法。

其中 `815-816` 排除了 offset table 与 trailer 之间的任何 gap；`818-822` 使用严格 `<=`，所以 256 个对象
不能宣称一字节 object reference，offset table 起点为 256 时也不能宣称一字节 offset。

## 3. 循环与被引用 fill 都必须失败

- `CFBinaryPList.c:1072-1074`：当前递归 path 已包含相同对象 offset 时直接失败。
- `1083-1097`：0x0 系只发布 null/false/true；fill `0x0F` 不在可发布 case 中，落入失败。

因此 fill 可以存在于对象区间作为 padding，但不能成为 offset table 条目或容器引用指向的 plist value。
Harmony 早期把它变成 null 会把恶意结构包装成合法数据；Phase 267 改为 parser error。循环仍沿用
Phase 163 的整份失败，不恢复旧 warning/null 占位。

## 4. v00 整数语义复核

`CFBinaryPList.c:1109-1112` 明确：format `00` 的 1/2/4-byte integer 按 unsigned 解释，8-byte integer 按
signed 解释；负的小整数会以 8 字节编码。当前 Harmony 已遵守该规则，本阶段只记录复核结论，没有把
1/2/4-byte 值错误改成有符号。

## 5. 重复字典键是 malformed，winner 行为不能跨解析器分叉

`CFBinaryPList.c:1573-1579` 明称文件可能 malformed 并包含 hash-equal duplicate dictionary keys；参考实现
把第二个值写入 CFDictionary 时会释放并覆盖先前值，即形成 last-wins。

Harmony `PlistValue.dictGet()` 从索引 0 正向返回首个命中，旧行为是 first-wins。若继续接受重复键，同一归档
可以在 Apple 与 Harmony 侧得到不同 `$objects`、`$top`、metadata 或业务字段。Phase 267 因此在
BinaryPlist parser 与 NSKeyedArchiver decoder 完整值图预检两层都拒绝重复键，不选择任一 winner。

## 6. Tracked OP-AMP 样本重放

归档：`test_notes/OP-AMP.note`

- 长度：603378 bytes
- SHA-256：`5F00C5A987D5E04EAEB90D2C9672C1C7196E3BF548392B75001D163F7FDF53EE`

三份 tracked binary plist 的 trailer identity：

| 样本 | 长度 | SHA-256 | offset/ref size | objects | table offset | 精确闭合 |
|---|---:|---|---|---:|---:|---|
| `Session.plist` | 558797 | `9E5F4D6CF61B3DD8E14E59BE31665DE661729934DF41FBBE1303E60153860CA7` | 4/2 | 308 | 557533 | `557533 + 308×4 = 558765 = length-32` |
| `metadata.plist` | 955 | `DDF7A11E6E82B92EAABD398B4692E05F6DA28D3A40E1D2486970DE38891BCE0F` | 2/1 | 97 | 729 | `729 + 97×2 = 923 = length-32` |
| `HandwritingIndex/index.plist` | 10271 | `0F7541601849E7CFA13EDC6610D1577C1FA74B88D6BB1253676C472F7921BB62` | 2/1 | 161 | 9917 | `9917 + 161×2 = 10239 = length-32` |

三者均满足 Phase 267 新门禁，说明该门禁拒绝的是非规范结构而不是已跟踪真实样本。

## 7. Hostile fixture 与 Replay

`docs/migration/replays/d02-cfbinaryplist-canonical-structure.mjs` 同时执行：

- 在 offset table 与 trailer 间插入一个字节，必须以 table-adjacency 失败；
- 256 个对象配一字节 ref，必须以 ref-width 失败；
- offset table 起点超过 255 配一字节 offset，必须以 offset-width 失败；
- 静态检查 production 的 fill、ordered-set、重复键和循环 hard-failure 分支；
- 检查 ArkTS fixture 不再期待“cycle warning + null”。

相关既有 replay：

- `d02-binary-plist-cycle-rejection.mjs`
- `d02-binary-plist-url-base-reference-validation.mjs`

## 结论

Phase 267 的实现不是 Android 原版逐行映射，而是 Apple 格式契约 + 真实样本 + Harmony fail-closed 适配。
精确 trailer 闭合、宽度承载能力、被引用 fill、ordered-set、重复键与循环现在具有一致的失败语义；任何未来
放宽都必须同时提供格式版本、真实样本、值模型和上层 consumer 证据。

# Phase 174 修复总结：BinaryPlist URL Base 引用校验

## 发现

此前 F-13 已支持 binary plist 的 URL-with-base marker，但解析器只解引用第二个 URL 字符串，首个 base 引用即使越界或形成循环也不会被访问，损坏对象图可被包装成成功。

## 修改

- `note/src/main/ets/data/BinaryPlistParser.ets`
- 新增 `ADR-0151-binary-plist-url-base-reference-validation.md`
- 新增 `d02-binary-plist-url-base-reference-validation.mjs`

`0x0D` 现在先通过 `objectAt()` 校验 base 引用，再读取 URL 字符串。输出仍保持当前字符串归一化，不凭缺少的消费证据扩展模型。

## 验证

- 新增 Replay：`TOTAL=5 FAILED=0`
- 循环引用回归 Replay：`TOTAL=4 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

URL、URL-with-base 越界与循环引用的恶意二进制样本仍需 ParserHostile runner 实际执行。

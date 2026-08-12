# Phase 163 修复总结：Binary plist 循环引用拒绝

## 发现

Binary plist 解析器检测到循环对象引用时原先写入 warning，并用 `null` 占位继续解析。这会把结构损坏的归档包装成成功结果，导致导入内容静默丢失。

## 修改

- `note/src/main/ets/data/BinaryPlistParser.ets`
- 新增 `ADR-0140-binary-plist-cycle-rejection.md`
- 新增 `d02-binary-plist-cycle-rejection.mjs`

循环引用现在通过 `ParseContext.fail()` 进入 `PlistParseResult.error`，整个 plist 被拒绝；正常的 UID 共享引用仍保持缓存解析逻辑。

## 验证

- Replay：`TOTAL=4 FAILED=0`
- `note@default assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- `note@ohosTest assembleHap`：本轮未执行，仓库无 `hvigorw` 启动脚本；此前同一工作树记录为 `BUILD SUCCESSFUL`
- 未启动设备、模拟器、虚拟机或 Hypium。

## 未闭环

真实恶意/循环 plist 样本和 NoteImporter 的用户可见错误提示仍需集成回放验证。

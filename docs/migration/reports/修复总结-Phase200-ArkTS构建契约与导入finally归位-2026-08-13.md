# Phase 200 修复总结：ArkTS 构建契约与导入 finally 归位

## 发现

Phase 199 的纯 HAP 构建继续暴露 12 个既有 ArkTS 编译错误：系统 Backup 直接重新抛出未限定的捕获值，
恢复回滚与资产迁移使用匿名对象类型，资产 JSON 临时值使用 ArkTS 不允许的 `unknown`。同时
`NoteImporter` 出现连续两个 `finally`，并在不持有 picker 文件变量的 `importNotability()` 中引用
`file`。

追溯提交 `0e37502b` 后确认，Phase 165 原意是保护 `importFromFile()` 的文件句柄，但兜底关闭被误加到
`importNotability()` 尾部。旧 replay 只在整个文件中搜索字符串，未验证资源清理所在函数，因此没能
发现错误归属。

## 修改

- `NoteBackupAbility` 新增命名 `RestoreReplacement`，回滚数组和入队对象均显式类型化
- Backup 创建/恢复失败统一重新包装为 `Error`，不再直接 `throw` 任意捕获值；已是 `Error` 时提取
  原始 message，避免 `Error: Error: ...` 重复前缀
- `DatabaseManager` 新增命名 `AssetReferenceRepairRow`，资产行快照不再使用匿名对象数组
- 资产 JSON 使用 `string[]` 静态类型，同时保留数组及逐元素 string 的运行时完整校验
- 将文件句柄关闭 `finally` 归位到 `importFromFile()`；`importNotability()` 只保留 mutex `release()`
- 升级文件句柄 replay 为按函数边界验证，避免“字符串存在但资源归属错误”再次漏检
- 更新系统 Backup 回滚 replay 以验证命名对象先登记、后复制
- 新增 ArkTS 构建契约 replay 与 ADR-0177

## 验证

- `assembleHap --mode module -p product=default -p buildMode=debug --no-daemon --no-incremental`：
  `CompileArkTS`、`PackageHap` 均通过，`BUILD SUCCESSFUL`
- Phase 200 专项 replay：4 个文件，`TOTAL=35 FAILED_FILES=0`
- 系统 Backup replay：9 个文件，`TOTAL=56 FAILED_FILES=0`
- WebDAV/批次及文件句柄回归：13 个文件，`TOTAL=79 FAILED_FILES=0`
- `git diff --check`：通过
- 未启动设备、模拟器、虚拟机或 Hypium

## 未闭环

构建输出仍包含大量既有 deprecated API 与“Function may throw exceptions” warning，后续将继续按
原版行为、Harmony 新 API 和实际风险边修边审；真实 picker/Backup I/O 故障仍需用户后续设备测试。
Goal 保持 active。

# ADR-0177：ArkTS 构建契约与导入 finally 所有权

## 决策

系统 Backup 的恢复回滚记录和数据库资产引用快照必须使用命名 interface，并在加入数组前构造
显式类型对象。`JSON.parse()` 的资产引用结果使用 `string[]` 作为 ArkTS 静态类型，但在任何元素
进入迁移逻辑前仍必须执行 `Array.isArray()` 和逐元素 string 校验，类型断言不得代替运行时验证。

Backup 捕获到的失败值不得直接 `throw`；状态记录完成后统一重新包装为 `Error`，满足 ArkTS 的
limited throw 约束，同时让 BackupExtensionAbility 调用方稳定收到异常对象。原值若已是 `Error`，
只提取其 `message` 后包装，避免对外形成 `Error: Error: ...` 的重复前缀。

`NoteImporter.importFromFile()` 独占 picker 文件句柄的 nullable 所有权，其异常兜底关闭必须位于
该函数自己的 `finally`。`importNotability()` 的 `finally` 只负责释放导入互斥锁。replay 必须按
函数边界检查两种资源，不能再以全文件字符串存在性代替所有权验证。

## 原因

Phase 199 的全量 HAP 构建暴露了命名类型、`unknown`、limited throw 等 ArkTS 编译错误。进一步追溯
发现 Phase 165 的文件句柄兜底 `finally` 因补丁定位错误被加到了 `importNotability()` 尾部，形成
连续两个 `finally`，既无法编译，也没有保护真正持有文件句柄的 `importFromFile()`。旧 replay 只
检查全文件中若干字符串，未验证它们属于哪个函数，因此错误位置仍能被误判为通过。

## 原版与平台边界

这些修改不改变 Notability 包解析、页面映射或写库语义，只修正 Harmony picker 文件句柄、互斥锁、
系统 Backup 与 ArkTS 类型系统的资源边界。Android 原版 1.0.3 没有 Harmony
`BackupExtensionAbility`、CoreFileKit picker 或 ArkTS 编译约束可逐行移植，因此本决策依据现有移植
行为与 Harmony 平台契约，不虚构原版对应实现。

## 验收边界

HAP 必须完成 `CompileArkTS` 和打包；静态 replay 负责防止资源所有权和命名类型回退。真实 picker
权限失败、文件短读、Backup I/O fault injection 仍需设备测试，静态检查不能替代运行态验收。

# ADR-0143: Note 导入输入文件大小预算

## 决策

`NoteImporter.importFromFile` 在读取 picker 文件内容前检查 `stat.size`，超过 `ZIP_MAX_ARCHIVE_BYTES` 或不是安全整数时立即拒绝。上限定义在 `ZipArchive`，避免导入入口与解析器使用不同预算。

## 原因

若先按文件大小分配 `Uint8Array`，恶意或误选超大文件会在 ZIP 安全预算生效前造成内存压力。前置拒绝不改变正常 `.note` 导入行为。

## 验收

静态 replay 检查共享常量、前置 stat 判断和拒绝前未执行完整读取；真实大文件和用户提示仍需设备验收。

# ADR-0142: Note 导入文件句柄生命周期

## 决策

`NoteImporter.importFromFile` 为 picker 选中的文件句柄建立 nullable 所有权；成功关闭后清空所有权，读取、stat 或导入异常时在 `finally` 中兜底关闭。

## 原因

文件短读、stat 失败或权限异常不应泄漏 CoreFileKit 文件句柄。该修复不改变取消、空文件和导入结果语义。

## 验收

静态 replay 检查所有打开路径都有 finally 兜底关闭；真实 picker 和权限失败仍需设备验收。

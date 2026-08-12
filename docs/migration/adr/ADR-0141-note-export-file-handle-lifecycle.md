# ADR-0141: Note 导出文件句柄生命周期

## 决策

`NoteExporter.exportToFile` 对临时、源和目标文件句柄使用显式 nullable 所有权。每个成功关闭后立即清空所有权，异常路径在 `finally` 中幂等关闭剩余句柄；临时和目标文件写入后调用 `fsyncSync`。

## 原因

picker 保存、短读或写入失败时，原实现可能跳过 `closeSync`，并留下未同步的导出文件。临时文件也必须使用 `TRUNC`，避免重用路径时尾部旧字节污染 `.note`。

## 验收

静态 replay 检查三类句柄的 finally 关闭、TRUNC 和 fsync；设备 picker 取消、权限失败和真实文件系统恢复仍需运行态验收。

# ADR-1234：.ntb 包格式 + 文件类型注册表

## 状态

已接受（Phase 1290）—— **里程碑**。

## 决策

`.ntb` ZIP{ManifestData+FlatBuffers ops+assets} → Harmony
`ZipFile`+手写 FlatBuffers；`nj3` MIME 注册表 →
`enum FileFormat{mime}`。

## 理由

`.ntb`=ZIP 归档（ZipEntry/putNextEntry + Kotlin
ManifestData manifest + FlatBuffers 笔记 ops + 资产）；
`nj3`=32-格式 MIME 注册表（Office/PDF/图像/音频/iWork/
笔记包）—— 文档导入/导出格式核心。

## 后果

Harmony 笔记包 = ZIP+FlatBuffers+ManifestData；文件
格式 = enum 注册表 —— .ntb 交换格式+导入/导出
语义保真。

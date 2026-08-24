# ADR-0385：原版照片归一化文件名

- 状态：已接受（2026-08-25）
- 场景：Android `bgj.d()` 用 `File.createTempFile("temp_", null, cacheDir)` 建立无扩展临时文件；`vuh.b()` 重写为 WebP 后，`bgj.d()` 仍以同一临时文件 `getName()` 作为 metadata fileName，同时保留新 MIME `image/webp`。Harmony 旧实现却把源 URI 扩展名固定拼到 `photo-N` 后，归一化为 WebP 时会出现 `.jpg`/`.png`/`.heic` 与 MIME 矛盾。
- 决策：规范化结果显式携带 `rewroteBytes`。字节被重写时照片入口采用 Android 等价的无扩展名 `photo-N`；未触发规范化时继续使用确定性诊断名 `photo-N.<source-extension>`。剪贴板粘贴本来就是重写后的 WebP 快照，因此其 ingress 结果也声明 `rewroteBytes: true`。
- 结果：metadata 文件名不再伪装旧编码格式，选择顺序、100 MiB 门限、失败清理和 fail-closed 语义不变。最终持久化仍按内容哈希定位，不依赖该诊断文件名。

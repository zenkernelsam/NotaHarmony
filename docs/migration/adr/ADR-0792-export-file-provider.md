# ADR-0792 — 1.0.1→1.0.3 文件级增量与导出完成追踪

- 状态：已接受（平台差异登记）
- 证据：`docs/migration/evidence/phase-848-export-file-provider.md`
- 回放：`docs/migration/replays/d02-export-file-provider.mjs`（12/12）

## 决定

1. 1.0.1→1.0.3 命名包层文件差分封存：**+2/−0**
   （`ExportFileProvider` + `ExportSweepWorker`），专用导出
   provider 取代通用 `FileProvider`，authority 不变。
2. 导出完成追踪语义登记：PFD 包装 + `OnCloseListener` +
   exportId 引用计数（1.0.3 `h64` map；1.4.2 重构为 `yx4`
   回调，语义等价）+ IOException 回收降级 + `ExportSweepWorker`
   孤儿清扫。
3. **Harmony 不复刻**：`DocumentViewPicker.save()` 为同步
   进程内复制，临时文件由 `finally` 清理——无异步 PFD
   消费方，close-tracking/sweep 机制在该模型下不成立；
   语义等价、机制不同，平台差异登记。

## 后果

1.0.1→1.0.3 命名包差分闭合；导出 share 模型的版本化
差异与 Harmony 等价性论证完成。

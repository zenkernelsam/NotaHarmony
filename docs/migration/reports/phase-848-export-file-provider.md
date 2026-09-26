# Phase 848 — 1.0.1→1.0.3 文件级增量 + 导出完成追踪

## 范围

`com.gingerlabs.notability` 包文件级 diff（1.0.1→1.0.3）+
`ExportFileProvider` 语义审计。

## 原版发现

### 差分：+2/−0

`ExportFileProvider` + `ExportSweepWorker`——命名包层
仅此两项（资源/vendor 差分 817 已记）。

### ExportFileProvider 语义

- 继承 FileProvider（1.0.3 `ye4` / 1.4.2 `x65` 混淆名）；
- `exports/<export-id>` URI 段提取 + 引用计数
  （1.0.3 `h64` map 开 +1/闭 −1；1.4.2 `yx4.b/c` 回调）；
- `ParcelFileDescriptor.wrap` + `OnCloseListener`——
  **share-sheet 异步消费完成的追踪信号**；
- IOException → `adoptFd` 回收 + 双通道日志 + 降级；
- `ExportSweepWorker` 配套清扫孤儿导出目录。

## Harmony 侧

`NoteExporter`：DocumentViewPicker.save 同步复制 +
`finally unlinkSync` 清理——无异步 PFD 消费，追踪/清扫
机制不成立；语义等价、模型差异登记。

## 验证

- Replay `d02-export-file-provider.mjs`：**12/12**
  （差分、provider 语义六断言、Harmony 模型三断言）。
- ADR-0792。

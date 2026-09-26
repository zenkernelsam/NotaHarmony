# Phase 848 — 1.0.1→1.0.3 类文件级增量 + 导出完成追踪

证据：`decompiled_1.0.1` vs `decompiled_1.0.3` app 包
`*.java` 文件级 diff + `ExportFileProvider` 源码。

## 一、版本差分（命名包层）

**+2 新增、0 移除**——非混淆包层极简：
`data/library/state/ExportFileProvider.java` +
`data/library/state/ExportSweepWorker.java`。
（资源/vendor 面差分 817 已记：Singular、FB/IG queries 等。）

## 二、1.0.1→1.0.3 导出基础设施更替

- 1.0.1：通用 `androidx.core.content.FileProvider`
  （authority `com.gingerlabs.notability.provider`）；
- 1.0.3 起：专用 `ExportFileProvider extends ye4`
  （FileProvider 子类；1.4.2 混淆基类为 x65）+
  `ExportSweepWorker`。
  authority 字符串未变（兼容已签名 URI）。

## 三、ExportFileProvider 语义（78 行）

`openFile(uri, mode)`：
1. `super.openFile` 取 PFD；
2. URI pathSegments `exports/<export-id>/...` → 取 exportId；
3. 1.0.3 实现：`h64.b` LinkedHashMap **引用计数**（open +1），
   `ParcelFileDescriptor.wrap(pfd, handler, OnCloseListener)`
   ——关闭回调 `h64.a(exportId)`（−1，归零即完成）；
4. `wrap` 抛 IOException → `adoptFd` 回收 + 双通道日志 +
   降级回原始 fd。
（1.4.2 重构为 `yx4.b/c` 直接回调——语义等价。）

`ExportSweepWorker`（845）：`exports/` 孤儿目录清扫配套。

## 四、Harmony 侧

`NoteExporter.exportNote`：临时文件写沙箱 →
`DocumentViewPicker.save()` 系统保存选择器 → 进程内
copyFileFully 至目标 → `finally` 同步 `unlinkSync(tmpPath)`。

**模型差异**：Harmony 导出是同步进程内复制（picker 返回
后完成），不存在 Android share-sheet 的异步 PFD 消费，
因此**无需 close-tracking/sweep**；临时文件生命周期由
`finally` 保证——机制不同、语义等价。

## 五、结论

1.0.1→1.0.3 文件级差分闭合：仅导出基础设施两件套；
完成追踪/清扫语义在 Harmony 同步导出模型下不成立，
登记为平台差异。

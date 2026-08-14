# ADR-0191：Note 导出必须完成全部文件写入

## 状态

Accepted，2026-08-14。

## 问题

`NoteExporter.exportToFile()` 对两个关键目标各调用一次 `fileIo.writeSync()`：

1. 应用私有临时 `.note` 包；
2. 系统 picker 返回的用户目标 URI。

旧实现忽略 `writeSync()` 返回值，随后直接 `fsync`、关闭并报告成功。Harmony SDK 明确规定返回值是“实际写入
的字节数”，并没有承诺始终等于请求长度。常规文件、内容提供者、空间不足、被中断 I/O 或其他平台边界都
可能出现短写；此时旧代码会生成截断 ZIP，却仍向用户显示导出成功。目标文件还使用 `TRUNC` 打开，因此失败
会覆盖原有同名内容，数据完整性风险高于单纯的临时文件残留。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/jv5.java` 使用 8192 字节 `BufferedOutputStream` 管理私有文件复制。
- `decompiled_1.0.3/sources/defpackage/fag.java` 的 `z(InputStream, OutputStream, long)` 循环读取 8192 字节，
  对每次实际读取长度调用 `outputStream.write(buffer, 0, length)`，直到 EOF 或预算超限。
- Java `OutputStream.write(byte[], offset, length)` 的调用契约由具体流负责完成请求长度或抛出异常；原版没有
  把“单次底层 channel write 的返回值可忽略”作为成功条件。
- Harmony 仓库中的 `ImageAssetPackageStore` 与 `OriginalRecordingPersistence` 已经对同一 `fileIo.writeSync`
  API 循环检查进度，说明完整写入是项目内既有正确适配方式。

## 决策

1. `NoteExporter` 新增 `writeFileFully(fd, bytes, label)`，临时文件和 picker 目标统一通过该函数写入。
2. 每轮最多取 64 KiB 的精确 `Uint8Array` 视图，并经 `exactArrayBuffer()` 转为不包含底层 view 外字节的
   `ArrayBuffer`，避免大包一次性交给 provider，也不回退 Phase 160 的精确字节边界。
3. 使用 `writeSync()` 的实际返回值推进总偏移，持续循环直到 `total === bytes.byteLength`。
4. 返回值小于等于 0 或大于本轮 chunk 长度都视为非法进度并抛错，防止零进度死循环、负值或不可信越界推进。
5. `fsyncSync()` 只在全部字节写完后执行。任何中途异常进入既有 `catch/finally`：返回失败、关闭所有仍归属
   本函数的句柄并删除应用临时包。
6. 保留目标 URI 的 `TRUNC` 与现有 picker 交互；本决策只修正写入完成条件，不改变文件名、格式或用户流程。

## 结果

- 短写会继续写完剩余字节，不再静默生成截断 `.note`。
- 无进度或异常写入不再报告成功，并复用现有句柄与临时文件清理路径。
- 临时包和用户目标使用同一完整写入契约，避免两条路径行为分叉。
- 每轮缓冲上限固定为 64 KiB，同时继续精确尊重 `Uint8Array.byteOffset/byteLength`。

## 边界

- 桌面 replay 通过可控短写计划验证顺序、无重复、无截断与零进度失败；真实 picker provider、磁盘满、I/O
  中断和权限撤销仍需设备故障注入。
- 目标 URI 已经以 `TRUNC` 打开；若 provider 在中途失败，用户目标可能保留部分文件。本阶段保证不会把它
  误报为成功，但跨 provider 的原子替换需要平台能力或独立 staging/rename 协议，不能在未知 URI 语义上伪造。
- 其他仍忽略 `writeSync()` 返回值的子系统应分别按其所有权和恢复协议审计，不因本 ADR 自动扩权修改。

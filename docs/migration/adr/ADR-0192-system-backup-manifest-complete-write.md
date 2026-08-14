# ADR-0192：系统 Backup manifest 必须完整同步后再发布

## 状态

Accepted，2026-08-14。

## 问题

`NoteBackupAbility.createSnapshotLocked()` 先把所有快照文件复制到 `nota-snapshot.staging`，再写
`nota-backup-manifest.json`，最后通过 rename 发布整个目录。旧 `writeText()` 只调用一次
`fileIo.writeSync()`，忽略实际写入字节数，也没有在发布前执行 `fsync` 或核对文件长度。

Harmony SDK 将 `writeSync()` 返回值定义为实际写入字节数。正数短写不会自动触发异常；旧代码因此可能把
截断 JSON 当作有效 manifest，随后把上一份可恢复快照移到 `previous`、发布损坏 staging，并最终删除旧快照。
这会把一个瞬态 I/O 问题升级为备份集合不可恢复，而且备份状态仍显示完成。

## 原版与移植内证据

- `decompiled_1.0.3/sources/defpackage/fag.java` 的私有文件复制 helper 使用 8192 字节循环读取，并把每次实际
  读取长度完整交给 `OutputStream.write(buffer, 0, length)`，直到 EOF 或预算超限。
- Phase 208 后的系统 Backup 已对每个快照对象使用 `copyFileVerified()`，比较源/目标长度与逐字节内容；manifest
  是同一原子集合的索引，不能比对象文件采用更弱的成功条件。
- Phase 182/183/208 已建立 staging、previous 回滚与在线 RDB 一致性。若 manifest 写入本身被误判成功，
  这些发布保护都会在错误输入上正常运行，反而稳定发布一个不可解析集合。

系统 Backup Ability 是 Harmony 平台适配层，原版没有同名 API；本决策复刻的是原版文件输出“完整写出或失败”
语义，并与移植侧已经建立的原子快照协议保持一致。

## 决策

1. `writeText()` 使用既有 `COPY_BUFFER_SIZE` 分块编码字节，循环读取 `writeSync()` 实际返回值并推进偏移，
   直到完整消费 `TextEncoder` 产生的 UTF-8 view。
2. 每轮 `ArrayBuffer` 从 `bytes.byteOffset + total` 精确切到当前 requested 末端，避免写入 TypedArray view 外字节。
3. 返回值小于等于 0 或大于本轮 requested 长度均视为非法进度并抛错，避免零进度死循环或越界推进。
4. 全部字节写完后对 manifest 文件执行 `fsyncSync()`；关闭后再确认路径仍是普通文件且长度严格等于编码
   字节数。
5. `createSnapshotLocked()` 只有在 `writeText()` 完整返回后才进入 `publishing`，移动旧 snapshot 和 rename
   staging。任何写入、同步、关闭或长度校验错误都会进入现有外层 catch，删除 staging 并保留旧 snapshot。
6. 保留 schema、manifest 内容与现有目录发布协议；本阶段只加强写入完成与耐久门禁。

## 结果

- manifest 短写会继续补写，不再静默发布截断 JSON。
- 零进度、异常、同步失败或长度不符会使备份失败并清理 staging，上一份已发布快照保持可恢复。
- manifest 与其索引的对象文件采用一致的“验证完成后才发布”原则。
- Phase 138 的精确 UTF-8 TypedArray 边界继续保留。

## 边界

- 桌面 replay 通过可控短写计划证明 UTF-8 字节序列完整、无重复及零进度失败；真实存储空间耗尽、I/O 中断、
  文件系统崩溃和 backup service 杀进程仍需设备故障注入。
- 文件 `fsync` 不等同于父目录 rename 的完整掉电耐久性。Harmony 当前 API 与系统 Backup 目录语义尚未证明
  可对目录 fd 执行通用同步；不能在缺少平台证据时宣称覆盖任意掉电窗口。
- 该修复不改变 restore manifest 的 schema 校验，也不解决外部系统备份服务是否再次复制已发布目录的时序；
  那些仍由现有 Backup Ability 协议和设备测试负责。

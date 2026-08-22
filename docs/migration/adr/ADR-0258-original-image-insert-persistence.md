# ADR-0258：原版本地图片插入的原子持久化边界

- 状态：Accepted（Phase 280，2026-08-22）
- 范围：已经过原版入口规范化的本地图片字节 → IMAGE CREATE_BLOCK → 本地资产与历史
- 相关：ADR-0135（原版 Block/IMAGE）、ADR-0240（clipboard transaction）、ADR-0241（全局实体身份）

## 决策

新增专用 `commitOriginalImageInsert()`，把图片文件、原版 IMAGE operation、`note_asset`、页面
snapshot/search/revision 和 durable history 作为一个调用方可观察的提交边界。锁序固定为：

```text
assetMutationMutex
  → 解码/哈希/文件准备
  → editorPersistenceMutex（即 databaseWriteMutex）
  → 单个 SQLite transaction
```

成功路径为：

```text
immutable normalized bytes
  → ImageKit header/PixelMap/EXIF gate
  → SHA-512 AssetHash
  → assets/pending write + fsync + atomic rename
  → IMAGE CREATE_BLOCK reducer + uploadable op
  → note_asset LOCAL merge
  → one page revision + snapshot/search + PageMutation history
  → SQLite commit
  → availability publish
```

## 原版对齐决策

1. 图片 intrinsic size 保留在 IMAGE metadata 和 `CREATE_BLOCK.size`；显示大小只写进 block transform
   scale，不用缩小后的显示尺寸覆盖 intrinsic size。
2. fit 同时受页面宽高各 `80%` 与 `320 / zoom` 限制；先以请求 anchor 为中心，再逐轴 clamp。
3. 原版关键 `float` 边界用 `Math.fround()` 重放；显示宽高分别回算 `scaleX/scaleY`，不把两者强行
   合并为一个 JavaScript double。
4. 入口最大 100 MiB；图片必须能实际 decode，尺寸必须是正整数且已经落在 3000px 边界内。
5. canonical asset key 是完整 SHA-512 的 128 位 hex；原版 FlatBuffer `AssetHash` 是八个 little-endian
   uint64 decimal word。两种表达必须可无损互转。

## 文件与数据库不变量

1. 输入 `Uint8Array` 在进入异步边界前复制；digest helper 返回独立字节副本。
2. final 文件只由同一 filesystem 内的 pending 文件 fsync 后 rename 发布。已有同 hash 文件必须逐字节
   相同，否则 fail closed。
3. 只有本次调用新建的 final 文件可在事务失败时补偿删除；复用的已有文件永不删除。
4. 已有 canonical/legacy `note_asset` 行在 CREATE_BLOCK reducer 前 reconcile，因为 reducer 对双行不同路径
   会正确拒绝，但本地入口持有已验证字节，能安全判断历史私有路径是否等价。
5. 私有目录内同内容旧路径改指 canonical final，但不删除旧文件；缺失旧路径可由 canonical 文件修复；
   私有路径内容冲突、应用目录外且仍可读的路径均拒绝并回滚。
6. reducer、uploadable operation、资产 LOCAL/UPLOADED/DOWNLOADED 状态合并、页面 revision、snapshot、
   search 和 PageMutation history 必须处于同一个 transaction。
7. `assetAvailabilityHub.publish()` 只能发生在 SQLite commit 返回以后。

## Harmony 适配

- Android `BitmapFactory + ExifInterface` 替换为 Harmony ImageKit `ImageSource.getImageInfo()`、
  `getImageProperty(ORIENTATION)` 与实际 `createPixelMap()`；header 或完整 decode 任一步失败都拒绝。
- `ImageSource` 与验证用 `PixelMap` 在 `finally` 中分别 release；清理异常记录但不覆盖主失败。
- 当前没有把 URI/FD/Pasteboard/相册权限和字节复制混入持久层；该层只接收 caller 已拥有的稳定字节。

## 明确未闭环

原版 `vuh.b()` 对任一轴超过 3000px 的输入会按最大边缩放、应用 EXIF 旋转，并以 WebP lossy 85
覆盖临时文件。本阶段没有实现 Harmony 重采样/重编码 adapter，而是对未规范化大图 fail closed。因此：

- 不能宣称任意相机/相册图片可直接插入；
- URI/FD/Pasteboard/系统相册 caller 与产品 UI 入口仍开放；
- 小尺寸带 EXIF 方向的字节由 Harmony renderer 如何显示仍需设备验证，当前 `ImageAssetLoader` 没有显式
  EXIF transform；
- 真实设备文件系统、解码、Undo/Redo、重启、导出/同步和视觉体验仍开放。

`T-042` APK 版本追踪继续严格留到整个 Goal 最后一项。

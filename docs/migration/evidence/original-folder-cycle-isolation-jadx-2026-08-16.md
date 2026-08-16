# 原版文件夹树与 Harmony 损坏循环隔离证据（2026-08-16）

## 范围

本证据对应 M2-U-05 的边修边审补丁。原版基准为
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`，移植侧为
`FolderRepositoryImpl.ets`、`LibraryPage.ets` 和 `FolderRepository.test.ets`。

## 原版硬证据

- `e47.java:353-354` 的 `SyncedFolderMetadata`/`ClientFolderEdit` 均保存 parent 与 siblingOrder，原版 folder 是树而非平铺列表。
- `beb.java:133-152` 在同一父级执行名称校验；`beb.java:154-171` 递归遍历真实 children 求子树最大深度。
- `xdb.java` 在移动前比较目标与自身子树，并以整个子树高度计算六层上限；原版正常写路径不会把无关循环当成目标后代。

## 发现的移植侧风险

Harmony 的 `isFolderInSubtree()` 为防止死循环使用 `visited`，但旧实现一旦检测到循环就直接返回 `true`。该 helper
同时用于删除子树：若数据库因旧版本、外部恢复或损坏出现一组与删除目标无关的循环 folder，删除任意正常 folder 时，
循环节点会被误收入 `deletedFolderIds`，其笔记也会被错误移到根目录。导航 fallback 又只处理缺失父级，循环节点完全不可达。

## 修复

- `isFolderInSubtree()` 仅在确实遇到 `rootId` 时返回 true；检测到无关循环返回 false，删除不会吸收不相关损坏组件。
- 移动安全没有放松：`validateFolderMove()` 随后的 `folderDepth()` 会对循环抛错，因此仍禁止把正常 folder 移入损坏循环。
- `LibraryPage.folderHasCyclicAncestry()` 只用于 UI 可达性 fallback；合法折叠子树仍不会被当作 orphan 重新显示。
- Hypium fixture 新增“正常 root + 无关 A↔B 循环”，验证后代判断、删除隔离和移动拒绝。

## 回放

`node docs/migration/replays/d02-folder-cycle-isolation.mjs` 输出：

```text
D02_FOLDER_CYCLE_ISOLATION_REPLAY_OK unrelated-cycle-delete=0|valid-descendant=1|move-rejects-corruption=1|navigation-fallback=1
```

这是损坏数据的静态/模型回放；真实旧数据库修复、UI fallback 排列与删除确认仍需设备或测试数据库验收。

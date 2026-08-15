# ADR-0182：资料库文件夹提交结果与共享元数据写者

## 决策

`NoteRepositoryImpl` 的创建、导入创建、更新、删除，以及 `FolderRepositoryImpl` 的创建、重命名、移动、删除和移动笔记，共用模块级 `libraryMetadataMutationMutex`。这把锁跨仓储实例生效，保证这些会修改 `note_meta`/`folder` 的事务按单写者顺序进入同一 RDB store。

删除笔记同时修改资产引用，因此固定锁序为 `assetMutationMutex -> libraryMetadataMutationMutex`。数据库事务提交后立即释放元数据锁；文件删除和资产可用性缓存清理由资产锁继续保护。导入流程只在单次笔记创建事务内持有元数据锁，不把它跨越到后续页面、笔迹或资产导入阶段，也不与 `editorPersistenceMutex` 嵌套。

文件夹写事务不再依赖提交后的 `getAllFolders()` 判断成功。创建、重命名和移动在事务内读取完成归一化后的文件夹快照；删除另外返回被删除的文件夹 ID、被移到顶层的笔记 ID，以及提交时的完整笔记元数据快照；移动笔记返回已提交的目标归属。只有 `commit()` 成功后这些结果才会交给页面。

`LibraryPage` 先发布仓储返回的提交结果，再独立启动文件夹、笔记和缩略图的最佳努力刷新。刷新失败只记录日志，不再把已提交的操作提示为失败。文件夹读取同时受 lifecycle、读取 generation 和 mutation generation 约束，旧读取不能覆盖更新的提交快照。

`LibraryViewModel` 对移动笔记和删除文件夹增加提交后投影，并推进既有 mutation generation：

- “全部笔记”中移动笔记会保留卡片并更新 `folderId`；从当前文件夹移出则立即移除卡片。
- 删除当前文件夹或其祖先时立即切回“全部笔记”；无搜索时使用事务返回的完整笔记快照，搜索中则保留已经确认仍有效的匹配卡片，再由权威查询补齐正文命中的结果。
- 删除事务没有报告为已迁移、但仍指向被删文件夹的旧卡片会被丢弃，避免并发移动/删除后的幽灵卡片。

标题保存继续保留 `NoteRepository.updateNote()` 既有接口，但实现改为标题字段补丁，只更新 `title`、`updated_at` 和标题搜索项。它不再把读取时的 `folderId`、`hasRecordings`、收藏或最近打开时间整行写回，从而避免覆盖排队期间已经提交的文件夹移动或录音状态。

Phase 245 / ADR-0222 进一步把该字段补丁升级为原版 `SET_METADATA.title` 事务。`updateNote()` 接口仍保留，
但现在委托给 title-only 原版 operation：生产 reducer 更新独立 LWW winner、标题与搜索项，随后原事务追加上传行
和可选 NTL1 history companion；`updated_at` 取当前值与 operation client time 的较大者。字段级不覆盖其他元数据
的决策保持不变，但“只做本地 SQL 补丁”的旧实现说明已被此阶段取代。

## 原因

此前 `FolderRepositoryImpl` 有私有静态写锁，而 `NoteRepositoryImpl` 使用其他事务边界；资料库页面的 `folderBusy`、`createBusy`、`deleteBusy` 又彼此独立。创建笔记、保存标题、删除笔记、删除文件夹或移动笔记可以从不同入口同时在同一 store 上开始元数据事务。即使 UI 暂时禁用某个按钮，导入、编辑器和其他仓储实例仍能绕过页面状态，因此 UI busy 标志不能承担仓储一致性。

页面还把仓储提交、`getAllFolders()`、`loadNotes()` 和缩略图刷新放在同一异常边界内。事务已经提交后，只要任何读取或渲染失败，用户仍会看到“创建/移动/删除失败”；重试可能制造重复文件夹，或让界面继续显示已经不存在的归属。

单纯增加互斥也不能解决旧快照覆盖：标题编辑会先读取完整 `NoteMeta`，若等待共享锁期间笔记已被移动，旧实现随后会把旧 `folderId` 连同标题一起写回。原版按字段合并客户端元数据，故 Harmony 侧必须使用同样的补丁语义。

## 原版证据

Android 1.0.3 的 `defpackage/jp1.java` 分别观察 `ClientFolderEdit` 和 `ClientFolderDelete`，再合并为文件夹客户端状态；`defpackage/beb.java` 观察 `SyncedFolderMetadata` 并与客户端编辑流组合。`defpackage/x17.java` 的合并查询把 `folderId`、`favorite`、`lastOpened` 等字段分别 `COALESCE`，而不是用一次整行旧对象覆盖新状态。

因此原版的 mutation 成败与后续响应式资料库查询分层，且元数据是字段级合并。Harmony 当前没有逐表复刻 Room/Flow，本决策用仓储级单写者、事务返回快照、本地确定性投影和最佳努力权威刷新保持等价的用户语义。

## 边界

本 ADR 只统一资料库笔记/文件夹元数据入口，并固定其与资产锁的顺序；它不是全局 RDB 事务锁。`editorPersistenceMutex`、页面仓储、资产到达、同步 inbox 等其他写者之间是否还会在同一 store 上交叠，需要后续按调用链继续审计，不能据此宣称全仓库事务并发已经闭环。

搜索状态下删除当前文件夹时，事务结果没有携带正文搜索匹配关系；本地投影只保证已有匹配卡片有效，完整结果依赖随后权威搜索刷新。设备生命周期、数据库故障注入和真实菜单交互仍需设备测试。

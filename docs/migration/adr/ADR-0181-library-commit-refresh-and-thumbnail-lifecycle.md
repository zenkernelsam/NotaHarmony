# ADR-0181：资料库提交后刷新与缩略图生命周期分层

## 决策

资料库创建和删除仍由 `LibraryViewModel` 的同一 mutation chain 串行执行，但仓储事务一旦成功，写操作就被视为已提交，不能再被后续列表读取、缩略图渲染或路由失败改判为写失败。

- 创建成功后，若用户仍处于点击时的列表视图且新笔记匹配当前查询，立即把仓储返回的 `NoteMeta` 加入当前快照并按现有模式排序。
- 删除成功后，立即从当前快照移除目标笔记。
- 权威列表读取由页面在提交后独立、最佳努力地执行；失败仅记录加载错误，不提示用户重试写操作。
- `loadNotes()` 同时记录读取 generation 与 mutation generation。若读取期间有本地写提交，迟到结果不得覆盖提交后的快照，而是重复当前查询。
- 创建和打开笔记分属两个错误边界：只有仓储创建失败显示“新建失败”，路由失败明确提示“笔记已创建，但暂时无法打开”。

缩略图刷新每代固定捕获一个 `ThumbnailRenderer` 和一个页面 lifecycle generation。页面离开时先让 generation 失效、换出 renderer，再通过同一 `thumbnailRefreshMutex` 等待已有 worker 结束后释放旧 renderer。页面重进通过幂等 `activatePage()` 恢复资产可用性订阅；旧初始化、旧加载和旧缩略图任务均不得向新生命周期发布状态。

## 原因

旧实现把 `repo.createNote/deleteNote`、`loadNotes`、缩略图刷新和导航放在同一异常链中。数据库事务已经提交后，只要任一后处理失败，UI 就会误报创建或删除失败：重试创建会产生重复空笔记，删除则可能保留已经不存在的卡片。

旧缩略图 worker 在 generation 检查后动态读取 `this.thumbRenderer`。页面离开可能在检查和调用之间换出 renderer，并同时释放旧 renderer；这会让 worker 使用未初始化的新对象，或在旧对象仍渲染时释放 pencil PixelMap、stroke texture 和 native bitmap。仅增加 thumbnail generation 不能约束 renderer 资源所有权。

## 原版证据与平台边界

Android 原版 Notability 1.0.3 的 `defpackage/veb.java` 使用 `ys2.r` 观察 `ClientNoteUpdate`、`SyncedNoteMetadata` 和 `PermanentlyDeletedNote`；`defpackage/x17.java` 再把这些状态表合并为资料库查询。原版因此把元数据 mutation 与响应式资料库查询分开，写提交不是由一次紧随其后的手工 reload 来决定成败。

Harmony 当前没有逐行移植原版 Room/Flow 管线。本 ADR 采用确定性本地快照、mutation generation 与最佳努力权威 reload 来保持同等用户语义；这是平台适配，不宣称是原版查询实现的逐行复刻。

## 边界

本次只分层资料库笔记创建/删除入口。文件夹创建、移动、删除以及移动笔记仍有各自的提交后刷新耦合，后续应按仓储返回值和可确定的本地投影分别处理，而不能在缺少完整提交上下文时盲目套用笔记删除逻辑。

真实页面前后台切换、低内存下 PixelMap 释放、路由失败和数据库读取故障仍需设备或故障注入验证；本阶段只执行静态 replay、ArkTS/Hypium 源编译和 HAP 打包。

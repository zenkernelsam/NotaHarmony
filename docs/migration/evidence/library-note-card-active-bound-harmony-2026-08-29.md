# Harmony 证据 — 资料库笔记卡片打开入口激活边界

日期：2026-08-29
阶段：Phase 527
结论：通过（静态验证）

## 代码证据

- `LibraryPage.NoteCard` 单击回调现在在 `router.pushUrl()` 前先检查 `!pageActive`。
- 失活卡片事件不再发起编辑器路由；缩略图可见性回调仍由 `requestVisibleThumbnail()` 的页面门禁处理。
- 长按菜单继续使用 `ResponseType.LongPress`，删除/移动动作和活动页单击语义不变。

## 静态验证

- 专项 Replay：`d02-library-note-card-active-bound.mjs` 输出 `TOTAL=4 FAILED=0`。
- 相邻库页创建/删除、查询 generation、文件夹选择/突变、初始化和主题/搜索 Replay 通过。
- 未启动模拟器、虚拟机、真机或 Hypium；`T-042` 继续保持 Goal 最后任务。
- 全量 Desktop Replay `422/422`（38.759 秒）；clean 2.908 秒、ohosTest HAP 9.343 秒、default HAP 48.457 秒静态构建成功。

# T-035 资料库增强：缩略图 + 搜索 + 排序

## 目标

资料库笔记卡片显示首页缩略图；搜索按标题过滤；排序可切换。

## 实现要求

### 1. 笔记缩略图

创建 `note/src/main/ets/rendering/ThumbnailRenderer.ets`：
- 输入：noteId → 加载第一页元素
- 用 OffscreenCanvas（如 300×400）离屏渲染第一页（纸张背景 + 笔画，等比缩放到缩略图尺寸）
- 输出 PixelMap，缓存到内存 Map<noteId, PixelMap>
- 笔记保存时异步刷新缩略图

修改 `LibraryPage.ets` 的 GridItem：缩略图 Image + 标题 + 更新时间。

### 2. 搜索

LibraryPage 搜索栏（已存在）→ 绑定过滤逻辑：
- 输入实时过滤 `notes.filter(n => n.title.includes(query))`
- 空结果显示"无匹配笔记"提示

### 3. 排序

搜索栏旁添加排序按钮 → bindMenu：
- 最近修改（默认，updatedAt DESC）
- 最近创建（createdAt DESC）
- 标题（title ASC）
选择后重新查询并刷新列表，排序偏好存 Preferences。

## 验收标准

- [ ] 笔记卡片显示首页缩略图（画过笔画的笔记可见内容）
- [ ] 搜索输入实时过滤标题
- [ ] 排序切换生效且持久化
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-035-完成.md`

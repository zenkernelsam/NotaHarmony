# ADR-0508：原版页书签——每页 LWW 寄存器 + 全链路物化

- 状态：已接受（2026-09-22，Phase 536）
- 背景：原版页书签是每页独立 LWW 寄存器——`oz9`
  （`UNBOOKMARKED=0/BOOKMARKED=1`）经 CreatePage 字段 3（`haj.a`，
  默认 UNBOOKMARKED）与 ModifyPage 字段 3（`u5j.s/t` → `r0j.a`）
  写入；`ge8.k()`/`ln2.k()` 解码时未知字节回退 UNBOOKMARKED；
  `wz9.java:42` 由寄存器胜者物化 `bookmarked`。Harmony 此前对
  携带 `bookmarked=true` 的 CreatePage 与携带书签字段的
  ModifyPage/bundle 一律 `BOOKMARK_UNSUPPORTED` 延迟，且不解析
  ModifyPage 字段 3——导入的书签状态被静默丢弃。

## 决策

1. Schema v70：`page_info` / `original_deleted_page` /
   `page_delete_checkpoint` 各加 `bookmarked INTEGER NOT NULL
   DEFAULT 0`；新建 `original_page_bookmark_winner` 胜者表
   （页序列身份主键 + 胜者身份 + `CHECK (bookmarked IN (0,1))` +
   CASCADE），与 position/visibility/background/page-in-asset
   胜者表同构；迁移从 `original_page_identity` 为既有页播种胜者。
2. 解码/编码：CreatePage 与 ModifyPage 均读字段 3（仅字节 1 →
   true，等价原版越界回退）；`encodeOriginalModifyPageBookmark`
   写 vtable 字段 3，缺省字段 vtable 项为 0，页向量 4 字节对齐。
3. 应用：CreatePage 移除书签延迟并以操作身份播种胜者 + 物化
   `page_info`；ModifyPage `applyBookmark` = 胜者读 → LWW 比较 →
   胜者写 + 活动/归档页物化；bundle 路径 `BootstrapPageState`
   携带 `bookmarked`/`bookmarkWinner`，`applyBootstrapBookmarks`
   在 fresh 与 existing-mapping 双路径物化，`existingMappingMatches`
   校验胜者行。
4. 运行时：`PageInfo.bookmarked` 全链携带（克隆/读写/检查点/
   归档恢复/导入导出/备份签名）；`PageRepository.setPageBookmarked`
   双路径——原版页走 `persistOriginalPageBookmark`（操作身份 +
   ModifyPage 应用 + appendOperation + 持久历史），本地页直接列更新。
5. UI：`PageManagerBar` 当前页 `🔖` 指示 + 开关按钮 + 紧凑菜单项
   （失败即关租约守卫）；`NotePage.toggleCurrentPageBookmark` 经
   `runPageOperation` 统一页操作闸门。
6. **刻意排除**：`bookmarked` 不进入 `PageStructureOpCodec`、
   `samePage`、`samePageInfo`、`changedPages`——可变寄存器不属于
   不可变结构相等性；否则删除推送与重做之间的书签翻转会令
   检查点校验失败。检查点/归档列仍携带书签以保证恢复保真。

## 理由

- 原版把书签建成寄存器而非页字段（wz9 由 `yc6` 寄存器胜者物化），
  胜者表镜像是最忠实的移植；把它塞进结构 codec 反而引入原版没有的
  耦合（结构相等性只覆盖不可变身份）。
- ModifyPage 字段 3 是可选写（`u5j.s` mask 控制），因此
  `hasBookmarked` 存在位 + 值分离解码；CreatePage 字段 3 有默认
  （haj.a 缺省 UNBOOKMARKED），缺省即 false。
- 归档页同样接受书签写（寄存器与可见性正交），故
  `updateMaterializedBookmark` 同时覆盖 `page_info` 与
  `original_deleted_page`。
- 多选开关语义（ae2 case 0：任一未书签 → 全书签）依赖页网格表面；
  Harmony 无缩略图网格，落点为当前页单选开关——选择集退化为 1
  时语义完全一致（未书签 → 书签，已书签 → 取消）。

## 后果

- 导入/同步的书签状态不再丢失；CreatePage 书签延迟移除后，携带
  书签的原始页创建可完整重放。
- 书签翻转推移 `BackupPageRevision` 签名——备份正确识别书签变更。
- `existingMappingMatches` 新增胜者行校验提高 bundle 重入一致性。
- 登记差异：无页网格 → 无多选开关与 BOOKMARKS 过滤 chip；
  图标以文本字形 `🔖` 适配（无 SymbolGlyph 先例）。
- Replay `d02-original-page-bookmark-parity.mjs` 50 项检查；
  全套 431/431；双 HAP 构建 0 错误。

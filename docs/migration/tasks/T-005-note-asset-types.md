# T-005 笔记/页面/资源类型

## 目标

创建笔记元数据、页面信息、纸张枚举和资源引用类型文件。

## 参考

- 知识库：REVERSE_ANALYSIS.md §7（纸张模板 lp0/e0a：8 种尺寸 + 6 种模板）、§8（Room 表结构：NoteStateEntity/SyncedNoteMetadata/NoteAsset）
- 契约：`docs/migration/phase-1-data-model.md` §3.6 和 §3.7

## 实现要求

### 创建文件

1. `note/src/main/ets/core/model/NoteTypes.ets`
2. `note/src/main/ets/core/model/AssetTypes.ets`

### NoteTypes.ets 必须导出

- `enum PaperSize { A3=0, A4=1, A5=2, A6=3, A7=4, LETTER=5, LEGAL=6, TABLOID=7 }`
- `enum PaperTemplate { PLAIN=0, LINES=1, GRID=2, DOTS=3, DIAGONAL_GRID=4, DECORATIVE=5 }`
- `enum PageOrientation { PORTRAIT=0, LANDSCAPE=1 }`
- `interface PageInfo`（8 字段：pageId/size/template/orientation/widthMm/heightMm + noteId 外键在数据库层）
- `interface NoteMeta`（9 字段：id/title/createdAt/updatedAt/favorite/lastOpened/folderId/hasRecordings）
- `interface NoteViewState`（4 字段：noteId/zoom/scrollOffsetX/scrollOffsetY）

### AssetTypes.ets 必须导出

- `enum AssetStatus { PENDING=0, LOCAL=1, UPLOADED=2, DOWNLOADED=3, FAILED=4 }`
- `interface NoteAsset`（6 字段：assetHash/status/noteIds/fileSize/mimeType/localPath）

### 依赖

- NoteTypes.ets: `import { Rect2D } from './GeometryTypes'`（如果用到，否则无依赖）
- AssetTypes.ets: 无外部依赖

### 鸿蒙特有约束

- 禁止平台 import。
- NoteMeta.folderId 类型为 `string | null`（根目录无文件夹）。
- NoteAsset.noteIds 类型为 `string[]`（多对多）。
- NoteAsset.localPath 类型为 `string | null`（未下载时无路径）。
- PageInfo 的 widthMm/heightMm 为 `number`（A4 默认 210.0/297.0）。

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] PaperSize 包含 8 个值，PaperTemplate 包含 6 个值
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-005-完成.md`

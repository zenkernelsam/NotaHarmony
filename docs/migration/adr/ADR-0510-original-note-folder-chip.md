# ADR-0510：原版笔记卡片文件夹标签——w09.g/h 投影 + 实心色胶囊

- 状态：已接受（2026-09-22，Phase 538）
- 背景：原版库笔记投影 `w09` 携带 `folderName`(g) 与
  `folderColor`(h，可空 Integer)；卡片 `cti.c` 在两者非空时经
  `e5j.b` → `i2j.b` 渲染实心文件夹色胶囊 + 名称文本，同一尾随
  行还渲染录音 mic（`w09.l` → `record_mic_outline`）。Harmony
  Phase 533 已落地 `folder.color`/`emoji`，但笔记卡片从未渲染
  文件夹标签——登记的视觉奇偶缺口。

## 决策

1. `NoteMeta` 增加 `folderName`/`folderColor`（`string|number
   | null`），对位 `w09.g/h`。
2. 仓储以**一次批量回查**替代 JOIN：`attachFolderProjection`
   收集非空 folderId → `SELECT id,name,color FROM folder WHERE
   id IN (…)` → 就地回填；所有列表出口（8 处）与单笔记路径
   （getNote/createNote/createNoteWithMeta）统一调用。
   `FolderRepositoryImpl.queryAllNotes`（文件夹删除 committed
   列表）同样回填，幸存文件夹笔记不丢标签。
3. VM 的字段重建助手携带新字段；`publishCommittedNoteMove`
   扩展为 `(noteId, folderId, folderName, folderColor)`——
   调用页从 `this.folders` 解析目标文件夹；unfiled/文件夹删除
   路径置空。
4. `NoteCard` 日期行后新增尾随 Row：chip 条件 = name 与 color
   双非空（`cti.c` 原条件），实心文件夹色胶囊（ARGB int 归一化
   `#AARRGGBB`）+ 亮度对比文本；`hasRecordings` → `🎙` +
   `recordings` a11y。chip 无视图条件——文件夹内部视图同样渲染，
   与 `cti.c` 一致。
5. **刻意排除**：`w09.k` 的 shared outline 不移植（Harmony 无
   共享模型，功能范围差异）；0.5dp 同色描边省略（同色视觉冗余）；
   文本色采用亮度对比而非原版的样式默认——原版调色板为浅色
    pastel 时默认深色文本成立，Harmony 调色板含深色，对比计算
   保证可读性（登记差异）。

## 理由

- 批量回查而非改写 SQL JOIN：现有 8 条查询中 6 条走
  `RdbPredicates`（不支持 JOIN），统一改为 SQL 成本与回归风险
  都更高；一次 `IN` 查询对卡片列表规模可忽略。
- 移动即时投影由页面提供 name/color：VM 不持有文件夹表，且
  `publishCommittedNoteMove` 之后本来就有 committed 重读校准——
  即时投影只需避免短暂错误标签。
- `folder.color` NOT NULL（Phase 533 决策）使 Harmony 侧
  "filed ⇒ 双非空"恒成立，与原版 `num == null` 守卫语义对齐
  （原版可空是为无配色文件夹准备的）。

## 后果

- 库卡片显示原版文件夹标签 + 录音指示；移动/删除文件夹的
  即时投影保真。
- 适配差异（已登记）：无同色描边、对比文本、🎙 字形、无
  shared 图标。
- 既有 replay 锚点合法更新 1 处（move-identity-bound 的
  publish 调用签名）。

# Phase 1423 证据 — 原版 Unindexed Notes 管理对话框（l8n.h 复刻）

## 原版证据链（decompiled_1.4.2）

### 宿主与打开条件
`zsb.java`（库主页组合）约 :1180-1200：

- 打开条件 `o(rgaVar4) && !(whfVar.b.isEmpty() || !whfVar.c.isEmpty())`
  → 即 `whf.b`（unindexed 集合）非空且 `whf.c` 为空时展示
  `l8n.h`。
- 行数据 `list3`：`whf.b ∪ whf.c` 经 `qcn.c(ycbVar, htbVarQ2.i, …)`
  投影为 `q0b`（`a`=id、`d`=日期、`g`=标题、`h`=数字）。
- **初始选集 = 全部**：`hashSet.add(w9b.a(((q0b) it2.next()).a))`
  循环预先加入所有 id（`r20`）。
- 确认动作 `dsb(ztbVar,1)`：`zq.e0(ztb.z(), …, psb(1,…,list,ztb))`
  —— 协程内对所选列表重建索引。
- 列表项开关 `objS57 = new dsb(ztbVar2,(byte)1)` 之外另有行切换
  `bz5`；dismiss `function6 = urb(rgaVar4,6)` 收起对话框。

### 对话框容器 `l8n.h`（l8n.java :2464+）
`m8n.a(function1=dismiss, new v24(7,false,false),
  p6f(function0,list,bz5,set) 内容)` —— 圆角对话框，内容 = `p6f`
case15。

### 内容 `p6f` case15（p6f.java :201+）
单列 Column（最大宽 614dp）：

1. `ec2.e` LazyColumn（`nlh` byte29 项）：首项经
   `aq8.j0(..., ubm.a)` 粘贴头 = `ig2(4)` =
   `unindexed_notes` 标题 + `unindexed_notes` 说明正文；
   后续行 = `uq5` case8。
2. 底栏 Column：
   - `o9n.a` 文本行 `strK`：`z3`（选集==全集）→
     `feature_library__deselect_all`，否则
     `feature_library__select_all`；onClick=`ch1` 全选切换。
   - 选集非空时 `d4i.b` 计数文本
     `R.plurals.feature_library__notes_selected`（one/other）。
   - `g8n.a` 按钮盒 = `y73(function3,bz5Var3,rgaVar,1)`。

### 行渲染 `uq5` case8 → `l8n.g`（uq5.java :332+ / l8n.java :2296+）
92dp 行：`z`（选中）→ `ui_designsystem__checkmark_circle`，
否则 `ui_designsystem__circle_empty_med_outline`；a11y 文案
`feature_library__select_note`；整行 `fq9.p` clickable 切换
`hsb` 回调；副题 `qbn.h(q0bVar.d)` = 日期串；行间 `hna.a`
分隔线（末行无）。

### 按钮对 `y73` default（y73.java default 支）
- `o9n.a(..., ui_designsystem__close, ...)` = Close（dismiss）。
- `f8n.a(z73(bz5Var,function0,rgaVar), enabled=z2=选集非空,
  content=ubm.b)`；`ubm.b = jf2(ig2(5))` =
  `feature_library__index_notes`（"Index Notes"）。
- `z73` default：`bz5Var.invoke(e52.i4(selectedSet))`（dsb 重建
  协程）随后 `function0.invoke()`（dismiss）。

### 相关资源
`feature_library__index_notes`="Index Notes"、
`select_all`/`deselect_all`/`select_note`/`notes_selected` 复数、
`unindexed_notes`/`unindexed_explainer`（既有横幅/说明文案）。

## Harmony 适配决策

- Harmony 无 WorkManager 索引队列；索引进度态
  （"Indexing N notes"/"All notes indexed"，`whf.a()` 驱动）在
  本移植中不存在对应异步管线 —— 同步落库即完成索引，该两支
  fail-closed 不适用。
- 管理对话框忠实复刻：标题+说明（粘性头等价固定头）、可选行
  （checkmark_circle/circle_empty_med_outline 双 glyph 既有）、
  Select All/Deselect All、notes_selected 复数（
  `note_selected_singular`/`notes_selected` 既有键）、
  Close + Index Notes（enabled=选集非空）。
- `reindexUnindexedNotes` 忠实范围：TITLE 项（`note_meta.title`
  经 `upsertTitleSearchItem`）+ 每页 TEXT_BLOCK 项（
  `page_element_snapshot` 持久化 payload 经
  `searchTextForElement` 解出折叠文本）+ `search_page_state.
  indexed_revision`。**INK 项**来自识别服务输出、**PDF 项**来自
  导入期文本抽取 —— 两者均无本地可重放源，保持 fail-closed
  缺席（与原版后台索引器的行为差：原版会重跑识别；本移植不重建
  这两类）。
- `getUnindexedNotes` = `countUnindexedNotes` 同谓词的完整投影
  （deleted_at IS NULL + NOT EXISTS search_item，updated_at DESC）。
- 行副题用 `updatedAt` + `Intl.DateTimeFormat(medium)`；标题空串
  回退 `untitled_note`。

# ADR-0660 原版引导气泡链（pq9 onboardingTooltipSeen）移植

- 状态：Accepted
- 日期：2026-09-26
- 关联 Phase：712
- 接续：ADR-0652（feature_learn 边界——FIRST_TRANSCRIPT 不带入本链）
- 证据：`docs/migration/evidence/original-onboarding-tooltips-jadx-2026-09-26.md`
- Replay：`docs/migration/replays/d02-original-onboarding-tooltips.mjs`

## 背景

原版 `data_onboarding__*`（12 条提示文案 + "Got it"）是一套顺序式
上下文引导气泡系统：

- `pq9.java` 枚举 12 种气泡：`NEW_NOTE`/`FIRST_TRAY_OPENED`/
  `FIRST_INK_INSERT`/`FIRST_IMAGE`/`FIRST_RECORDING`/`FIRST_TRANSCRIPT`/
  `FIRST_TEXT`/`FIRST_IMPORT`/`FIRST_UNDO_REDO`/`FIRST_HIGHLIGHTER`/
  `FIRST_NOTE_COMPLETED`/`COMPACT_ORGANIZE`。
- `hq9.java`：datastore 键 `onboardingTooltipSeen` 持久化
  `Set<String>`（枚举名），读回经 `pq9.valueOf` 容错映射
  （未知串记录并跳过）。
- `fsi.g`/`fsi.h`：每条气泡条件 = `!seen(kind) && 站点上下文`
  （调用方布尔），渲染 `zy7` 气泡（本地化文案 + "Got it"）。
- `k9f.java`：锚点方位 1=上/2=下/3=左/4=右 + RTL 变体 + 越界回退。
- `js7`："Got it" 点击 → 对应 `pq9` 写入 seen 集并落盘。
- 前置序：`rh8` z6=`!seen(L) && seen(I)`（录音气泡需 NEW_NOTE
  已见）；`ys2:1493` 同款前置用于 `FIRST_TRAY_OPENED`。

站点解码（逐位证据）：

| pq9 | 站点 | 方位 | 上下文条件 |
|-----|------|------|-----------|
| I NEW_NOTE | rh8/cq.p（笔记态 e5f） | 通用宿主 | 编辑器挂载 |
| J FIRST_TRAY_OPENED | ipi:1533 | 托盘宿主 | 样式托盘打开 && seen(I) |
| K FIRST_INK_INSERT | rh8/cq.p（k5f 墨迹态） | 通用宿主 | 笔记含墨迹 |
| * FIRST_IMAGE | 通用宿主（mq9.b 挂起流） | — | 图像对象存在 |
| L FIRST_RECORDING | gaj:875/rh8:1936 | 3 左 | `!seen(L) && seen(I)` && 有录音 |
| M FIRST_TRANSCRIPT | cqi:207 | 3 左 | Learn 转写面（ADR-0652 边界） |
| * FIRST_TEXT | 通用宿主 | — | 文本工具语境 |
| N FIRST_IMPORT | x90:10523 | 3 左 | `z7` 任一页有内容 |
| O FIRST_UNDO_REDO | x90:10528 | 3 左 | `gl8Var5` undo 可用 |
| * FIRST_HIGHLIGHTER | 通用宿主 | — | 荧光笔工具语境 |
| P FIRST_NOTE_COMPLETED | ajh:406 | 4 右 | 库侧有笔记 |
| Q COMPACT_ORGANIZE | enh:28 | 2 下 | 库侧有笔记 |

（`*` = 枚举字段声明被 JADX 丢弃的三种，经通用宿主 `mq9.b` 挂起流
驱动；锚点文案语义已标明各自归属面。）

## 决定

1. **移植 11 条气泡**；`FIRST_TRANSCRIPT` 隶属 feature_learn
   转写面（ADR-0652 已 fail-closed），不进入本链。
2. **`OnboardingTooltipStore`**（`data/`）：preferences 承载
   `onboardingTooltipSeen` 逗号连接串，等价原版
   `Set<String>` 枚举名集合；`getSeenKinds` 过滤未知串
   （对齐 `pq9.valueOf` 容错）；`markSeen` = js7 等价物。
3. **`OnboardingTipBubble`**（`ui/components/`）：深色气泡 +
   本地化文案 + "Got it"（`zy7`/`tpe.b` 等价物）。
4. **锚点实现**：
   - 工具栏类锚点走 `bindPopup`（`mask:false` 保持原版非模态
     语义，`autoCancel:false` 保证仅 "Got it" 关闭——对应
     js7 唯一关闭路径）；`pos3→Placement.Left`、`pos4→Right`、
     `pos2→Bottom`。
   - `NEW_NOTE`/`FIRST_TRAY_OPENED` 锚定样式选项按钮（"expand
     the tool's styling options" 文案所指控件；原版包编辑器
     全域，功能等价锚点）。
   - `FIRST_INK_INSERT`/`FIRST_IMAGE` 为画布内元素锚定浮层
     （元素非 ArkUI 组件，bindPopup 无法附着——
     `tipOverlayPosition` 实现 `k9f` 越界回退：上→下、左→右）。
   - `FIRST_TEXT`/`FIRST_HIGHLIGHTER` 锚定对应工具按钮，工具
     首次选中触发（通用宿主语境的功能等价站点）。
   - `FIRST_IMPORT` 锚定页管理器开关 ▦（`z7` 任一页有内容 =
     `!emptyNoteActions` 直通）。
   - `FIRST_UNDO_REDO` 锚定撤销按钮（`gl8Var5` undo 可用）。
   - `FIRST_RECORDING` 锚定 Recordings 按钮（`seen(NEW_NOTE)`
     前置逐位对齐 rh8 z6）。
   - `FIRST_NOTE_COMPLETED` 锚定首张笔记卡（pos4 右），
     `COMPACT_ORGANIZE` 锚定 Folders 入口（pos2 下，侧栏
     New Folder / compact ☰ 抽屉两布局各一锚）。
5. **文案逐位**：12 条 `data_onboarding__*` 键名/英文原文与
   原版逐位一致；中文为等义直译。

## 差异记录

- `NEW_NOTE`/`FIRST_INK_INSERT`/`FIRST_IMAGE`/`FIRST_TEXT`/
  `FIRST_HIGHLIGHTER` 的原版精确锚点坐标不可静态复现
  （通用宿主 `i01` 自适应方位 / 字段声明缺失）；Harmony 按
  文案语义锚定到所述控件或元素包围盒，方位取 `k9f` 默认上→下
  / 左→右回退——已在上表逐条标注。
- 原版 `pq9` 之间除 I→{J,L} 前置外无显式排序；Harmony 同款。
- `mask:false` 下气泡与底层控件可同时命中——与原版非模态
  coachmark 一致。

## 后果

- 新用户首次进入编辑器/插入内容/打开托盘/选择工具时获得与原版
  同序的上下文提示；"Got it" 持久抑制。
- 已见过全部气泡的旧安装（seen 集迁移自原版语义集合）不产生
  任何新 UI。

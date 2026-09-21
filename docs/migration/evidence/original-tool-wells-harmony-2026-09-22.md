# Harmony 证据：原版按工具颜色/粗细井位 + 全局最近色（SCHEMA-D2）— 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）ToolboxDatabase 的井位模型，补齐
Harmony 此前"只存选中下标、不存井位内容"的差异（Phase 530 登记的 SCHEMA-D2）。

## 原版证据

### 三张玉声明（defpackage/e47.java）

- `e47.java:377` `FavoriteColorWellEntity(id AUTOINCREMENT, toolType TEXT, color INTEGER, trayIndex INTEGER)`
- `e47.java:378` `WidthSizeWellEntity(id AUTOINCREMENT, toolType TEXT, width REAL, trayIndex INTEGER)`
- `e47.java:382` `RecentColorWellEntity(id AUTOINCREMENT, color INTEGER, timestamp INTEGER)`
- 三表均无二级索引；`e47.java:379` `ToolStateEntity` 内嵌
  `selectedColorWellIndex`/`selectedWidthSizeWellIndex`（`wp1.java:552` 列序确认）。

### 默认播种（defpackage/rz1.java + gr7.java）

`gr7.java` 首启一次性写入 `rz1.p()`（收藏色井）与 `rz1.s()`（粗细井）：

| toolType（a6f） | 收藏色（trayIndex 序） | 粗细井（trayIndex 序） |
| --- | --- | --- |
| PEN (I) | -16777216, -15260469, -2011583 | 1.0, 2.0, 4.0 |
| PENCIL (J) | -16777216, -15260469, -2011583 | 1.5, 3.0, 5.0 |
| HIGHLIGHTER (K) | -172, -4391597, -1428530 | 20.0, 15.0, 10.0 |
| ERASER (M) | — | 4.0, 7.5, 15.0 |
| LASER (R) | -1754827, -14776091, -12345273, -141259 | 15.0 |
| REVIEW (S) | -1706497, -672330, -6303021, -11872, -2238485 | 12.0, 36.0, 64.0 |

`ba8.java`（迁移 case 24）另对 REVIEW 井位做删后重播，说明播种语义是"初始化时
整体写入、升级时定点重播"。

### DAO 语义

- 收藏井 upsert（`i8f.java:541-562`）：先 `SELECT WHERE toolType=? AND trayIndex=?`，
  存在则保 id 换色（`qb4.a(qb4Var, color, 0, 11)`），否则 `new qb4(0, toolType, color, trayIndex)` 插入。
- 收藏井删除（`tb4.java:25-46`）：先 `UPDATE ... SET trayIndex = trayIndex - 1 WHERE
  trayIndex > ? AND toolType = ?`，再按 id 删行。
- 读路径自愈（`i8f.java:246-261`）：若末行 `trayIndex >= list.size()`（下标不稠密），
  逐行重写 `trayIndex = 位置`（`qb4.a(obj, 0, i3, 7)` + `zl2` 批量 upsert）。
- 宽度井：仅见 `INSERT OR REPLACE` upsert（`na4.java:605`）与 REVIEW 重播删除；
  无 trayIndex 下移 SQL，删除留下的空洞靠读路径自愈吸收。
- 最近色（`ehb.java` + `m2a.java:139` + `ss3.java`）：
  1. `SELECT WHERE color=?` 命中则保 id 刷新 timestamp（`bhb.a(existing, now)`）；
  2. 未命中且 `count >= 7`：先 `DELETE ... ORDER BY timestamp ASC LIMIT count-6`
     裁到 6 条，再插入——上限恒为 7；
  3. 读 `ORDER BY timestamp DESC`；`ehb` 注入工具交互层 `i8f`（`w7f.java:54-68`），
     即笔刷色写入路径顺带记最近色。
- 工具栏 VM 状态 `jg9.java` 直接携带 `favoriteColorWells`/`widthSizeWells` 列表，
  `sw1.java` 携带 `recentColors`——弹层渲染的是数据库井位而非编译期常量。

## Harmony 落点

### Schema（DatabaseHelper.ets，版本仍 67）

```sql
favorite_color_well(id INTEGER PK AUTOINCREMENT, tool_type INTEGER NOT NULL,
                    color INTEGER NOT NULL, tray_index INTEGER NOT NULL)
width_size_well  (id INTEGER PK AUTOINCREMENT, tool_type INTEGER NOT NULL,
                    width REAL NOT NULL, tray_index INTEGER NOT NULL)
recent_color_well(id INTEGER PK AUTOINCREMENT, color INTEGER NOT NULL,
                  timestamp INTEGER NOT NULL)
```

- 列名走全库蛇形惯例（ADR-0504）；`tool_type INTEGER` 与 `tool_state.tool_type` 同域。
- 不升版本：三表经 `ddlList` 每次打开幂等建表（同 Phase 530 索引策略）。
- 默认播种映射：`PEN=3 / HIGHLIGHTER=4 / PENCIL=5 / REVIEW=6 / WHOLE_ERASER=7`；
  LASER 无 Harmony 对应工具，不播种（ADR-0504 如实登记）。

### 仓库（ToolRepositoryImpl）

`getFavoriteColors / setFavoriteColor / removeFavoriteColor / getWidthWells /
setWidthWell / removeWidthWell / getRecentColors / recordRecentColor /
seedDefaultToolWells` 九方法逐条对应上述原版 DAO 语义；全部写操作经
`databaseWriteMutex` + 事务（沿用 Phase 5xx 确立的全局写者纪律）。

### ViewModel + UI

- `EditorViewModel`：`favoriteColors / recentColors / widthWells` 观察字段；
  `initialize` 内 `seedDefaultToolWells()` + `refreshWells()`（井位失败不阻塞工具态
  初始化，仅走 `onPersistenceError`）；`selectTool` 后刷新当前 toolType 井位；
  `setBrushColor` 成功后 `recordRecentColor`。
- `setBrushColor/setBrushWidth` 的 `selectedWellIndex` 默认改为 **-1**：井位点按
  传真实下标，色板/最近色点按表示"未选中任何井位"。
- `ColorPicker`：收藏井网格 → 最近色行 → 12 色预设色板（保留为自定义取色来源）。
- `WidthSlider`：滑块上方渲染当前 toolType 粗细井槽位，点按携带井位下标。

## 验证

- `docs/migration/replays/d02-original-tool-wells-parity.mjs`：97 项检查通过——
  原版锚点 24 项、Harmony schema/接口锚点 43 项、可执行语义模型 30 项
  （最近色去重+上限7+时间戳刷新；收藏井 upsert 保 id / 删除下移 / 读路径自愈）。
- 全量 Desktop Replay：427/427（本仓根目录执行）。
- `hvigor clean` + `note@ohosTest` + `note@default`：全部 BUILD SUCCESSFUL，
  0 个 ArkTS ERROR；触改文件仅出现库内既有的 "may throw exceptions" 类警告。

## 残留差异（如实登记）

1. 原版收藏井长按进入编辑模式可用自定义色轮写井；Harmony 已提供仓库/VM 层
   `setFavoriteColorWell`/`removeFavoriteColorWell`/`setWidthWellAt`/`removeWidthWell`
   API，但弹层尚无编辑交互入口（后续增强）。
2. LASER 井位未播种——Harmony 无 LASER 工具；若未来补 LASER，播种表需扩展。
3. 原版 REVIEW 井位升级重播（`ba8` case 24）在 Harmony 无对应物——Harmony 首启
   已含 REVIEW 默认井位，无需重播路径。
4. `selectedColorWellIndex = -1` 是 Harmony 对"非井位取色"的显式语义；原版默认
   全为 0，未找到原版写 -1 的直接证据（ADR-0504 记录此决策）。

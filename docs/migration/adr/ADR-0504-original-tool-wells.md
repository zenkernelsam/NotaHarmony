# ADR-0504：原版按工具颜色/粗细井位采用蛇形列名持久化，井位索引以 -1 表示"未选中井位"

- 状态：已接受（2026-09-22，Phase 532）
- 背景：Phase 530（ADR-0502）逐表比对确认原版 SCHEMA-D2——原版 ToolboxDatabase
  持有三张井位表：`FavoriteColorWellEntity`（按 toolType 的收藏色井）、
  `WidthSizeWellEntity`（按 toolType 的粗细井）、`RecentColorWellEntity`
  （全局最近色，按 color 去重、上限 7、timestamp DESC），且 `ToolStateEntity`
  内嵌 `selectedColorWellIndex/selectedWidthSizeWellIndex`。Harmony 此前只持久化
  两个选中下标，井位内容为 `ColorPicker` 内 12 色硬编码数组，粗细井与最近色完全缺失。

## 决策

1. 新表沿用 Harmony 全库蛇形命名惯例而非原版驼峰：`favorite_color_well`、
   `width_size_well`、`recent_color_well`；`toolType`→`tool_type INTEGER`（与
   `tool_state.tool_type` 同域），`trayIndex`→`tray_index`，`timestamp` 同名保留。
   原版三张表均无二级索引，Harmony 同样不建索引。
2. 版本不升（仍为 67）：三表走 `ddlList` 每次打开的幂等 `CREATE TABLE IF NOT EXISTS`
   路径，与 Phase 530 索引同策略；既有库与全新库一致到达。
3. 首启播种镜像 `gr7`：仓库层 `seedDefaultToolWells()` 在整表为空时一次性写入
   `rz1.p()/s()` 默认井位（PEN/PENCIL/HIGHLIGHTER/REVIEW 收藏色；PEN/PENCIL/
   HIGHLIGHTER/ERASER/REVIEW 粗细井），幂等可重复调用；原版 LASER 无 Harmony
   对应工具，明确不播种。
4. 语义逐条对齐原版 DAO：`setFavoriteColor` 按 (tool_type, tray_index) upsert 保留 id
   （`i8f`）；`removeFavoriteColor` 先 `tray_index-1` 下移再删行（`tb4`）；
   `removeWidthWell` 只删行（原版宽度井无下移 SQL，靠读路径自愈）；
   `getXxx` 读路径在末行 `tray_index >= 行数` 时重写稠密下标（`i8f` 自愈）；
   `recordRecentColor` 按 color 去重刷新时间戳、新色先裁最旧至 6 再插入（`ehb`，上限 7）；
   `getRecentColors` 按 `timestamp DESC`（`m2a`）。
5. UI：`ColorPicker` 渲染"收藏井（按当前 toolType）→ 最近色 → 12 色预设色板"三段；
   `WidthSlider` 在滑块上方渲染当前 toolType 的粗细井槽位。井位点按携带下标，
   色板/最近色点按传 `selectedWellIndex = -1`（"未选中任何井位"——原版井位语义只
   属于收藏/粗细井，预设色板是 Harmony 保留的自定义取色来源）。
6. 应用任意笔刷色即写入最近色（`setBrushColor` → `recordRecentColor`），对齐原版
   工具交互层 `ehb` 注入位置。

## 理由

- 原版工具栏 VM 状态（`jg9`）直接携带 `favoriteColorWells`/`widthSizeWells` 列表，
  证明弹层渲染的是数据库井位而非常量；硬编码数组因此确认是移植期占位实现。
- 蛇形列名与 INTEGER tool_type 是 Phase 530 确立的 Harmony 库内一致性约定；
  原版 TEXT 枚举名在 Harmony 无字符串域，强求同款只会产生死映射。
- `-1` 表示"未选中井位"：原版默认态全部为 0（指向首井），而色板取色不对应任何
  井位行，-1 是唯一不产生误导高亮的诚实值；列无 CHECK 约束可安全存储。
- 空表才播种而非逐 toolType 检查：原版 `gr7` 同样一次性整体播种，二次执行只会
  因初始化门控不发生；Harmony 以"整表为空"作等价门控。

## 后果

- `EditorViewModel` 新增 `favoriteColors/recentColors/widthWells` 观察字段与六个
  井位读写 API；`FakeToolRepository` 同步实现井位方法（测试编译通过）。
- 弹层行为变化：收藏井成为第一区（替代原硬编码网格的主导位置），最近色行按
  实际使用累积出现；12 色预设色板保留为自定义取色来源。
- 未实现的残留差异（如实登记）：原版收藏井支持长按编辑/自定义色轮写井，
  Harmony 仅提供仓库+VM 层 API、暂无弹层编辑交互；原版 LASER 工具不存在故无
  LASER 井位；井位行数为原版默认（3-5/工具），非用户可调密度。
- Replay `d02-original-tool-wells-parity.mjs` 97 项检查可执行复放以上语义。

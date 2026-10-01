# ADR-1348：Library Home "Coming Up" 日历分区移植

- 日期：2026-10-01
- 状态：Accepted（功能等价；权限/观察机制与 Syllabus 源为登记差异）
- 关联：Phase 1412；`docs/migration/evidence/phase-1412-home-coming-up.md`；
  Academic Planner（Phase 1406）；Auto note title（ADR-1347）

## 背景

原版 1.4.2 Library Home 顶部存在 **Coming up** 分区（`vkm.a` 次序：
CTA → kan.a → exams → unindexed → favorites → recents）：

- 数据源 `jt1`：`CalendarContract.Instances` 查询 `[今日0点, +10天0点)`、
  `visible=1`、`begin ASC`，`cbl` 游标映射为 `ag1`（DECLINED 跳过、
  allDay UTC→本地午夜、空标题渲染层回退）；权限 `y14.a()` 判
  `READ_CALENDAR`；`kg3` ContentObserver 监听日历变更重查。
- 模型 `m70` case7 → `kb2{days,isReadable}`：`end>now` 过滤、跨日进行
  中事件 clamp 到今日、组内 begin 升序、今日组恒在前。
- 行 `nan.f`：副标 All day / `ofLocalizedTime(SHORT)`；`lb2.a` 10 分钟
  阈值给出 `STARTING_SOON`/`HAPPENING_NOW` 包装文案与改色；尾部
  "Start now" 钮 → `ne` case11 → `c13.a(…, ik.CALENDAR, title,…)`
  以事件标题建笔记并打开。
- 面板 `nan.i`：`za2` 窗口 = ≤3 日分组且 ≤10 事件；`nan.g` ‹/› 翻页
  （earlier/later_days 无障碍标签、边界禁用）；组间 `nan.b` 分隔线；
  空组 `nan.e` = "No upcoming events" 卡。
- 不可读 → `e7n` Connect 卡（Events at a glance / 副标），整卡点击
  经 `oye.n0(READ_CALENDAR)` 发起运行时授权。
- `zf1.SYLLABUS` 源（`lhh` 课表条目，EXAM 标签 + 文件夹引用）合流同一
  列表并驱动 `q8n.e` 考试卡。

## 决策

1. **设备日历全量移植**：Harmony `calendarManager` +
   `ohos.permission.READ_WHOLE_CALENDAR`（声明于 `module.json5`，含
   `reason`/`usedScene`）覆盖 `y14.a()`/`jt1`/`cbl` 语义。事件窗口、
   allDay 换算、空标题回退、分组/窗口/行状态全部按原版实现。
2. **Connect 卡整卡点击 = 权限请求**（`oye.n0` 等价
   `requestPermissionsFromUser`）；授权成功即重拉，拒绝停留 Connect
   卡（原版语义）。
3. **`kg3` 观察者差异**：Harmony `calendarManager` 无全局变更回调 →
   在每次 Home 呈现（`onPageShow` → `loadNotes` 完成）刷新分区。
   考虑到 Home 页打开频率与事件窗口短周期（10 天 + 10 分钟态），
   该刷新点覆盖原版语义的实际可见场景。
4. **`selfAttendeeStatus`/`visible` 过滤不移植**：Harmony `Event` 无
   自身参与状态与可见性字段；系统 Provider 只回当前日历可见事件，
   DECLINED 事件差异登记为平台限制。
5. **SYLLABUS 源与考试卡 fail-closed**：`lhh` 为后端课表数据（含
   `EXAM`/`folderRef`），Harmony 无对应后端/同步层；`q8n.e` 考试卡
   分区不在本 Phase。`ComingUpEventSource.SYLLABUS` 枚举位保留。
6. **`Start now` 行为 = 建笔记并打开**：复用 `createAndLaunch` 增加
   `titleOverride`（`vm.createNote` 第四参，非空即跳过自动标题工厂，
   对应 `c13.a` 显式 title / null 分支语义）；事件标题 blank →
   `undefined` → 默认标题管线（"New Note"/自动标题）。
7. **样式细节**：`f8n.a` 布尔位次序脱壳受限 → 以"lma 变体切换
   （非 UPCOMING accent / UPCOMING subtle）+ 按钮恒可点"实现；
   `nan.i` 拖拽翻页手势与 `cb2`/`w60` 分析回调不移植（非功能差异）。

## 后果

- 用户授予日历权限后 Home 呈现与原版一致的 Coming Up 面板；未授权
  看到原版 Connect 卡并可一键授权。
- `nan.i` 的 rga 选中态语义保留：按窗口起始日记忆、数据重载后归位、
  找不到回落首窗口。
- 事件行单击建笔记走既有 `createAndLaunch` → `repo.createNote` →
  `bundledDefaultApply` → `router.pushUrl(NotePage)` 全链路，自动套用
  默认模板（原版 `c13.a` 管线同等路径，文档差异：无 `ik.CALENDAR`
  埋点/分析标识，Harmony 无分析总线）。

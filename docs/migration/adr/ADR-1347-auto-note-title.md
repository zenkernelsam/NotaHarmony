# ADR-1347：Document Defaults 自动笔记标题移植

- 日期：2026-10-01
- 状态：Accepted（行为等价；特性可见性为有意差异，见后果）
- 关联：Phase 1411；设置页体系 ADR 系列、标题策略（200/256 上限）

## 背景

原版 1.4.2 在 `noteEditorSettings`（o8b）持久化三键：
`defaultNoteTitle` / `includeDatePosition` / `includeTimePosition`。
`k59.l(创建时刻)` 经 `o8b.f` → `mcn.g` 组装自动标题：
前缀日期/时间 + 基题（自定义非 null 覆盖 "Note" fallback，空串亦覆盖）
+ 后缀日期/时间，空分量丢弃、空格 join；结果 blank → `"..."。
日期=ofLocalizedDate(MEDIUM)（zq.d/tgh(10)），时间=
ofLocalizedTime(SHORT)（zq.e/tgh(11)）。

设置侧：`document_defaults`→`note_title` 子屏（yob/ibb/a96）=
200 码元字段 + 字段非空时尾部清除钮 + include_date/time 三态行
+ `Example:` 实时预览（草稿字段值直喂 mcn.g，不走 fallback）。

**关键差异点**：整条特性被 `h35.R0=DOCUMENT_DEFAULT_SETTINGS`
（`qd5` 调试旗标，`PRODUCTION ≤ DEBUG` 不满足）门控——出货版
设置行隐藏、`k59.l` 恒走 `k()` 返回 "New Note"。

## 决策

- **无条件开放**：Harmony 无 flag 基建；把一个完整可移植的特性
  调试门控反而丢失原版设计行为。`k59.l` flag-off 分支语义由
  fail-closed 路径覆盖（工厂缺失/异常 → "New Note"）。
- **同键同 store 持久化**：preferences `noteEditorSettings`；
  title 缺键→`null`（区分「从未设置」与「显式清空=''」——空串
  覆盖 fallback，与 `str2 != null` 判定等价）；position 存
  hmi 英文名，非法值回落缺省（date=Suffix、time=None）。
- **格式化等价**：`Intl.DateTimeFormat` medium/short（随系统
  locale，等价 tj.withLocale 重建）；`/\S/` 判定 blank（与
  Kotlin isWhitespace 同域）；组装顺序/单空格 join/`"..."` 兜底
  与 mcn.g+k59.l 一致。
- **创建路径注入**：`LibraryViewModel` 持有可选
  `noteTitleFactory`，`createNote` 在建库行内 `Date.now()` 取值
  （对应 `k59.l(currentTimeMillis)` 建时格式化）；工厂失败
  fail-closed → "New Note"，笔记照常创建。
- **设置 UI**：Document Defaults 区置于 note_editor 段后（原版
  目录顺序 document_defaults 属独立子屏入口，Harmony 扁平化为
  单页内分区）；字段 `maxLength(200)`（je case11）、清除钮
  `close_med_regular`+圆底（xmark_circle_fill 等价合成）、
  三态行 → `TitlePositionDialog`（勾选标记=general_check_med_reg，
  与 n94 单位选择器同构）、Example 用进屏时刻（remember{now}）。

## 后果

- 用户可见差异：Harmony 出货包即显示 Document Defaults 设置区，
  且默认配置（Note + date Suffix）下新笔记标题为
  "Note <medium date>" 而非 "New Note"——这是原版设计行为
  （flag-on 语义），非回归。
- zh 串按既有术语风格新译（文档默认值/包含日期/前后缀）。
- 预览不套 fallback：字段为空时示例只剩日期/时间分量，
  与 a96 一致。

## 验证

`d02-original-auto-note-title.mjs`（112 checks）+ 两处既有
fixture 重锚定；`note@default`/`note@ohosTest` 构建通过。

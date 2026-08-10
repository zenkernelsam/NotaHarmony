# ADR-0012：原版 Ink style map、稳定 backing 状态与独立 LWW

- 状态：Accepted（单 center-path component 与 DASH/DOTS phase 的受证明子集）
- 日期：2026-08-10
- 关联：D-02、数据库 v34、ADR-0004、ADR-0006、ADR-0011

## 背景

原版 `yyd` 是 20-byte inline struct：signed int32 `backingPencilSeed` 位于 offset 0，Pencil reference point 的
两个 float 位于 offset 4/8，`backingDashPhase` 与 `backingDashPeriod` 位于 offset 12/16。`ddg.java:236`
要求非空 style map 与 center path 的每个 move-to component 一一对应。

`q06.java:620` 证明 MODIFY_INK field 12 进入独立的 `styleMapRegister`，而不是 style、custom path 或 effects
的附属字段。`s06.a0()` 在 winner 存在时采用 winning vector，否则回退 CREATE_INK field 13。空 vector 是
winning clear，和 field 缺席不同。`p16.java:239-254` 使用第一项 seed/reference 构造 Pencil，`ft1.java` 使用每个
component 的 `backingDashPhase` 计算 DASH/DOTS phase；`s06.X()` 还让第一项 phase 参与 effects。ADD_PATH_ELEMENTS
只追加 center path，不携带新的 style map。

## 决策

1. `StrokeElementData` 增加 `styleMap`，逐项保存 signed seed、Pencil reference、dash phase 和 period；自有包只接受
   int32 seed 与有限浮点。
2. FlatBuffer reader 增加带元素宽度和总数量预算的 inline-vector 读取。CREATE_INK field 13 建立 fallback，
   MODIFY_INK field 12 作为独立 nullable vector LWW；field 缺席不修改，空 vector 清除。
3. 当前 center-path decoder 只证明单 component，因此 CREATE/MODIFY 只接受空 map 或一项。多 component payload
   明确 DEFERRED/MALFORMED，不猜测 component 拆分。
4. 数据库升至 v34，分别保存 `create_style_map`、winning value、winner timestamp/site 和 presence。旧 v33 行首次
   winning 修改从保留的 CREATE_INK envelope 恢复 fallback；多 Ink 先全量核对当前派生状态，再与 snapshot、revision、
   搜索失效和 inbox cursor 在同一事务提交。
5. 剪贴板、编辑器快照、Undo、选择、擦除和路径追加均保留 style map。DASH/DOTS renderer 读取第一项
   `backingDashPhase`，按当前 pattern period 归一化后设置 Canvas `lineDashOffset`。
6. `backingDashPeriod` 和 Pencil seed/reference 继续原样保存，但在 Pencil/effects reducer 完成前不宣称已消费。

## 后果与验证

- `d02-modify-ink-style-map.mjs` 覆盖真实 field 12 inline struct、signed seed/float、空 vector clear、v33→v34、
  legacy CREATE fallback、严格 LWW、多 Ink 原子性、迁移/应用回滚、dash renderer consumer 和无本地日志。
- ArkTS fixture 覆盖 CREATE field 13、MODIFY field 12、数据库 v34 DDL 与离屏 DASH phase 像素断言；style map 在
  包解析和所有笔画复制路径中保留。
- 全部 25 个 D-02 桌面 replay 通过；clean 后 `note@ohosTest` 与 `note@default` assembleHap 均 BUILD SUCCESSFUL。
- Canvas 与 Android dash phase 的正负方向、原版同笔迹像素对照和设备 Hypium 尚未执行。nib、Pencil/Tape、effects、
  NOTE_BUNDLE 内容 replay 与 block/text payload 继续未完成；本 ADR 不关闭完整 MODIFY_INK 或 D-02。

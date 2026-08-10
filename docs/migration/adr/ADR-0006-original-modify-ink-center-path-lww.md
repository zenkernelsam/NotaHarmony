# ADR-0006：原版 MODIFY_INK center-path 独立 LWW register

- 状态：Accepted（center-path 受证明子集；字段门禁由 ADR-0007 扩展）
- 日期：2026-08-10
- 关联：D-02、数据库 v28、ADR-0004、ADR-0005

## 背景

原版 `MODIFY_INK=17` 的 `wd8` 可同时指向多个 Ink，并包含 page/origin、rotation、scale、style、tape pattern、color、width、
center/custom/fill path、fill color、style map、z-index、nib、effects 等字段。`q06` 不使用一个整对象 winner；每个字段对应独立
`fqb` register。`fqb.c()` 仅当新 op 的 `qo5(timestamp,site)` 严格大于当前 winner 时替换该字段，相等或更旧的 op 是 no-op。
CREATE_INK 的 op ID 是各 register 的初始 winner。

center-path replacement 与 `ADD_PATH_ELEMENTS` 是两个不同域。replacement 改写基础 center path register，但不会删除此前或随后到达的
append records；最终几何始终由当前 winning base path 加全部按追加 op ID 排序的真实片段重建。若只覆盖当前 JSON 曲线或在替换时清空
append history，乱序同步将与原版分叉。

## 决策

数据库升至 v28，为 `original_ink_state` 增加 `center_path_winner_timestamp/site_id`。新 CREATE_INK 以自身身份初始化 winner；v27
迁移将既有 state 的 winner 回填为目标 Ink 身份。v26 及更旧的无 state Ink 继续明确 DEFERRED，不反推原始压缩路径。

新增 `OriginalModifyInkOperationApplier`，v28 阶段仅接受以下 payload：

- `inks` 是 1～10000 个不重复的 8-byte `qo5`；
- 可选字段只有 field 8 `encodedCenterPath`；
- center path 属于 CREATE_INK 已证明的单 component、可无损解码子集。

任一其他 `wd8` field 同时出现时，整个 op 返回 `MODIFY_INK_ADDITIONAL_FIELDS_UNSUPPORTED`，不能只应用 center path 后把 inbox
标为 APPLIED。仅含 targets 而无修改字段的合法 no-op 可直接消费。

对每个目标先解析 stable element/page identity 与 v28 state。op ID 不大于该目标 center-path winner 时不改写；winning target 则：

1. 读取 live snapshot 或远端删除归档中的 Stroke 与全部原始 append BLOB；
2. 用旧 base + appends 重建并严格核对当前持久化 geometry；
3. 用候选 base + 同一批 appends 重建 replacement，VARIABLE style 仍要求逐点属性；
4. 所有目标预检通过后，才在外层 inbox 事务中 CAS 更新 base/winner 与 stroke payload；
5. 同一页即使包含多个 winning Ink，也只推进一次 content revision 和搜索失效。

远端 reducer 仍不写本地 `operation_log` 或 Harmony Undo/Redo。page/origin、rotation、scale、style、tape、color、width、custom/fill、
style map、z-index、nib 与 effects 的独立 register 尚未实现；后续必须逐字段保存 winner/value，不能退化为一个全对象时钟。

## 后果与验证

- center-path replacement、append 到达顺序和目标 Ink 列表顺序不再影响最终路径；append history 保留并按新 base 重新连接。
- 同一 MODIFY op 对多个目标是全有或全无；任一 state/geometry 分歧不会留下部分 winner 或部分页面更新。
- `d02-modify-ink.mjs` 覆盖真实 19-field `wd8`、field 8 布局、v27→v28、CREATE winner 回填、严格 LWW、多 Ink 单 revision、
  append 保留/重连、live/archive、unsupported-field 门禁、分歧原子性、故障回滚、缺 state 与无本地日志。
- ArkTS fixture/DDL 契约已注册。未运行设备 Hypium 或真实服务乱序流，也不据此宣称完整 MODIFY_INK 或 D-02 已完成。

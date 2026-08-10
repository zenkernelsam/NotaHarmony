# ADR-0007：原版 MODIFY_INK style/color/width 独立 LWW register

- 状态：Accepted（winner 初始化语义由 ADR-0008 修正）
- 日期：2026-08-10
- 关联：D-02、数据库 v29、ADR-0006

## 背景

原版 `q06.c()` 对 `wd8` field 5 style、field 6 color、field 7 width 分别调用独立 `fqb` register；同一个 MODIFY_INK 中，
某字段可能 winning，另一个字段可能 stale。把三者或整个 Ink 共用一个 winner 会错误丢弃乱序操作。style 改为 VARIABLE_WIDTH 时，
当前 center path 与全部真实 append 还必须具备逐点属性；width 会重新决定原版 `cq.H()` 几何的 `2 * baseWidth` bounds padding。

数据库 v28 的既有 `original_ink_state` 没有保存这三个初始值。直接把当前 Harmony snapshot 当成原版 register 初值，会把本地编辑或损坏
误认成同步真值，失去分歧门禁。已应用的 CREATE_INK 原始 envelope 仍保存在 `synced_operation_inbox`，可作为权威恢复来源。

## 决策

数据库升至 v29，在 `original_ink_state` 中为 style、color、width 分别保存 value 与 `(timestamp,site)` winner。v29 曾用 CREATE
身份占位 winner；原版 `xj2.k()` 证明 winner 初始应为空，该占位已由 ADR-0008/v30 的 `*_winner_present` 修正。旧行第一次收到
winning render 修改时，从同一 Ink 身份对应的
CREATE_INK 原始操作恢复初值并与当前 Stroke 对照；缺 envelope、解析失败或值分歧均整体 DEFERRED，不猜测初值。

`OriginalModifyInkOperationApplier` 同时开放 field 5/6/7/8，并遵循以下规则：

1. 四个字段独立比较 winner，只应用 winning 子集；其他 `wd8` 字段仍使整个操作 DEFERRED。
2. 多 Ink 先全部读取、恢复旧值、验证几何和计算候选，再进行任何写入。
3. style/color/width 与 center path 可在同一操作组合；最终 bounds 使用 winning width，VARIABLE_WIDTH 检查 winning base 及全部 append。
4. 每个受影响页面只推进一次 content revision 并失效笔迹搜索；远端 reducer 不写本地 operation log 或 Undo。
5. 原版只拒绝非有限 width，但 Harmony 的 renderer/bounds 无法可靠表达负宽度；负值返回
   `MODIFY_INK_WIDTH_UNSUPPORTED`，不静默钳制或写入坏几何。

page/origin、rotation/scale、tape、custom/fill path、fill/style map、z-index、nib 与 effects 仍未开放，继续返回
`MODIFY_INK_ADDITIONAL_FIELDS_UNSUPPORTED`。

## 后果与验证

- style/color/width 的乱序到达不再互相覆盖 winner；同值的新操作仍推进自己的 register 身份。
- width replacement 会从原始 base + 有序 append 重建 bounds，不只改 `renderSpec.brushWidth`。
- `d02-modify-ink-render.mjs` 覆盖 field 5/6/7、v28→v29、旧 CREATE 初值恢复、三 register 独立 LWW、多 Ink 单 revision、
  width bounds、unsupported/负宽门禁、VARIABLE 属性门禁、分歧原子性、故障回滚与无本地日志。
- 未执行设备 Hypium 或真实服务乱序流，不据此宣称完整 MODIFY_INK 或 D-02 已完成。

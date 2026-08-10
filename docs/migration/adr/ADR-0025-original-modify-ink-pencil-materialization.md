# ADR-0025：原版 Pencil MODIFY_INK 确定性重新物化

- 状态：Accepted
- 日期：2026-08-11
- 关联：D-02、ADR-0006～ADR-0012、ADR-0023、ADR-0024、数据库 v41（无 schema 变化）

## 背景与原版证据

原版 1.0.3 的 `q06.c()` 对 `MODIFY_INK=17` 只更新 page/origin、rotation、scale、style、color、width、
center/custom/fill path、fill color、style-map 和 z-index 等独立 LWW register。中心路径 winner 改变时会清除内部缓存，
但 `s06` 模型本身不持久化 Pencil splats。渲染器 `p16.t()` 每次读取最新 `s06.Q()`、`s06.c0()` 和
`s06.a0()`，再用 style-map 第一项的 seed/reference（或固定 fallback）从完整中心路径重新执行 `wg6.q()`/`cfa`。

因此 Pencil 的 winning MODIFY 不能保留旧 snapshot splats，也不需要新增 end-seed 或 walker cursor。以最新 register 候选构造
完整 stroke 后，从 base center path 与全部有序 actual appends 重新生成 splats，和原版最终物化模型等价。

## 决策

`OriginalModifyInkOperationApplier` 现在允许 `renderSpec.isPencil=true`。应用任一 winning register 前，先用旧完整状态重建
path points、cubics、splats 和 bounds，并与当前 snapshot 全量比较；任何分歧均保持 DEFERRED。随后以候选 path、width、
style-map、auxiliary paths 和 transform 再完整重建，并让最终 replacement 消费新 `geometry.splatPoints`。

center-path、width 或 style-map 会改变局部 splat 序列；rotation、scale 和 page/origin 不改变局部 splats，但会改变 world bounds。
统一走完整重建避免不同 register 形成两套物化规则。Pencil 沿用原版无属性路径的默认 force/altitude/azimuth，因此不套用 Pen
VARIABLE_WIDTH 的属性门禁。非 Pencil snapshot 携带 splats 仍视为损坏。

CREATE/ADD 已采用的 262,144 splat 同步输入预算同样约束 MODIFY。旧状态或任一候选重建超限时返回
`MODIFY_INK_PENCIL_SPLAT_BUDGET_EXCEEDED`；所有目标先完成规划才开始写入，外层 inbox 单事务保证多 Ink 修改不截断、不部分写入、
不推进 revision。

## 验证与边界

- `d02-modify-ink-pencil.mjs` 覆盖 width/style-map 重建、transform 局部稳定、预算失败零修改及生产 consumer/source 门禁。
- `PencilSplatGenerator.test.ets` 增加 width 改变 spacing/scale，以及 winning seed/reference 改变序列的断言。
- 全量 34 个 D-02 replay 通过；clean 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。
- 设备 Hypium 与原版像素对照未执行。estimated append、Tape/effects 和 NOTE_BUNDLE 内容 replay 仍保持 DEFERRED，完整 Pencil
  同步与 D-02 均不关闭。

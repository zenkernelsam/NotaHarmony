# ADR-0023：原版 CREATE_INK Pencil splat 确定性物化

- 状态：Accepted（standalone CREATE 子集）
- 日期：2026-08-11
- 关联：D-02、ADR-0004、ADR-0017、数据库 v41（无 schema 变化）

## 背景

ADR-0004 曾将 `CREATE_INK(PENCIL)` 保持为 DEFERRED，因为没有证明 Pencil 随机种子来源，且没有 splat 的
Pencil 在 Harmony renderer 中不可见。后续 style-map 阶段已经无损保留原版 `yyd` 的 seed/reference 字段，当前统一
`StrokeElementData`、持久化、复制、选择、擦除和 renderer 也都能承载 `splatPoints`，因此可以重新核对该边界。

原版 1.0.3 的直接证据来自 `p16.t()`、`s06.G()`、`yyd`、`wg6.q()`、`cfa.b()` 与 `zea`：

- `p16.t()` 从第一项 `s06.a0()` 读取 `yyd.f()` 作为 Pencil seed；没有 style-map 时固定使用
  `1544949492L`，不是随机值或 op timestamp；
- `yyd.e()` 的非零 reference point 传入 `wg6.q()`/`cfa`，作为首个 `spacing/4` 曲线步进的距离参考；
  `(0,0)` 被原版调用方视为没有 reference；
- `cfa.b()` 将负的 int32 seed 符号扩展到 long 后取绝对值，再进入模数为 `1946926193` 的 LCG；
- `s06.G()` 对 Pencil 先把基础宽度乘以 `2.84`，再交给通用 `cq.H()` 做 `2 * width` padding。
  持久模型 bounds 因此仍基于中心路径控制点凸包，不改成逐 splat 的更紧包围盒；
- `p16.t()` 从保存的原始中心曲线直接重建 splats，不重新拟合。

## 决策

`PencilSplatGenerator` 的默认 seed 改为原版 fallback；`reset()` 对负 seed 取绝对值；`generate()` 新增可选
reference point，并只改变第一段距离步进。现有实时落笔仍显式按 stroke start identity reset，调用契约不变。

`OriginalCreateInkOperationApplier` 现在接受 tool `PENCIL=1`：以已解码的原始 cubic、逐元素 force/altitude/
azimuth、基础 width，以及 style-map 第一项生成确定性 splats；没有 style-map 时使用固定 fallback。生成结果连同
`renderSpec.isPencil=true`、原始 style-map 和 `2.84` Pencil bounds 一起进入既有 live/archive snapshot 事务，重启后
直接读取保存的 splats，不依赖再次随机生成。

非 attributed Pencil 路径按原版 `fd0` 默认属性处理；Pen 的 VARIABLE_WIDTH 属性门禁保持不变。Tape、pattern、
audio 和 effects 仍不做降级。

## 边界与验证

- 本阶段只开放 standalone `CREATE_INK(PENCIL)`。Pencil `ADD_PATH_ELEMENTS` 与 `MODIFY_INK` 仍返回各自的
  DEFERRED 原因；NOTE_BUNDLE 内容 replay 也尚未接入，不能宣称完整 Pencil 同步闭环。
- `d02-create-ink.mjs` 新增真实 tool=PENCIL 和 20-byte style-map FlatBuffer fixture。
- `d02-create-ink-pencil.mjs` 固定断言 fallback seed、负 seed、reference point、splat golden、Pencil bounds 和
  JSON 持久化重启往返。
- `PencilSplatGenerator.test.ets` 新增负 seed 与 reference point 断言。全量 33 个 D-02 replay 通过；clean 后
  `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。设备 Hypium 和原版像素对照未执行。


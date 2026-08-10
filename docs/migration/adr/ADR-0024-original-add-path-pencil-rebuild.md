# ADR-0024：原版 Pencil ADD_PATH_ELEMENTS 完整路径重建

- 状态：Accepted（actual center-path 子集）
- 日期：2026-08-11
- 关联：D-02、ADR-0004、ADR-0023、数据库 v41（无 schema 变化）

## 背景与原版证据

ADR-0023 已恢复 standalone `CREATE_INK(PENCIL)`，但 `ADD_PATH_ELEMENTS` 仍会因 Pencil 返回 DEFERRED。需要判断
移植侧是否必须额外持久化 LCG end seed 和曲线 cursor，还是可以从完整路径确定性重建。

1.0.3 的 `q06.c()` 将 type 16 的 actual center-path elements 按 op identity 排序并并入 Ink 路径 register；`s06` 不保存
Pencil splats。渲染时 `p16.t()` 每次读取完整 `s06.Q()`，再以 style-map seed/reference 调用 `wg6.q()`，从第一 component
开始重新执行 `cfa` walker。因此对当前仅支持的单 component Ink，从 base path 和全部有序 appends 重建完整 cubic 后重新生成
所有 splats，与原版最终模型等价；单独保存中间 walker 状态反而会引入原版模型不存在的第二真相源。

## 决策

`rebuildOriginalInkGeometry()` 现在同时重建 path points、cubic segments、Pencil splats 和 bounds。Pencil 使用 ADR-0023
已证明的 seed、reference、属性插值和 `2.84` bounds 系数。新 append 应用前，base path + 已存 appends 的完整重建结果必须与
当前 snapshot 的路径、cubic、splats、bounds 全部相等；任一分歧均保持 DEFERRED。成功后加入新 append、按 op identity 重新排序，
再重建并原子替换 live 或 archive snapshot。

非 Pencil stroke 出现 splats 视为状态分歧。Pencil 不要求 VARIABLE_WIDTH 路径携带属性，因为原版 `fd0` 对无属性路径提供
默认 force/altitude/azimuth；Pen 的 variable-width 属性门禁不变。estimated center path、多 component 和 Pencil
`MODIFY_INK` 在本决策中继续保持 DEFERRED，后续分别由 ADR-0026 和 ADR-0025 在相同完整重建模型上开放。

边修边审补上同步 Pencil 物化的输出预算：输入路径即使受 16MB 限制，极小 width 与超长坐标仍可令等距 walker
产生近乎无界的 splats。CREATE/ADD 共用 262,144 上限，超限整项 DEFERRED，不截断、不写 append，也不推进 revision；
实时本地书写不使用该远端输入预算。

## 验证

- `PencilSplatGenerator.test.ets` 证明完整路径延长后，旧路径生成的全部 splats 是新结果的严格前缀，并验证预算
  超限抛出专用错误而不是返回截断结果。
- `d02-create-ink-pencil.mjs` 同时锁定负 seed/reference、追加前缀、ADD source consumer 与 Pencil bounds；既有
  `d02-add-path-elements.mjs` 继续覆盖乱序重连、live/archive、搜索失效、分歧和事务回滚。
- 全量 33 个 D-02 replay 通过；clean 后 `note@ohosTest` 和 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。
  设备 Hypium 与像素对照未执行。

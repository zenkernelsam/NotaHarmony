# ADR-0085：把本地 partial eraser 持久化为 tool-5 Ink（已废止）

## 状态

Superseded，2026-08-15。由 ADR-0214 取代。

## 更正原因

本 ADR 在 Phase 108 把两件事错误地等同起来：

- 原版枚举与 CREATE_INK reducer 确实认识 tool 5；
- 原版本地 partial-erase 手势的最终页面持久结果。

重新直读 `dh5`、`o8j`，并对普通 JADX 缺失的 `jt1.invokeSuspend()`、`wc.invoke()` 做 JADX 1.5.6
fallback 线性反编译后，证据表明这两个语义不同。tool 5 用于 partial-erase 交互输入，也可能存在于历史/输入
operation 中；但手势提交并不会永久保留一条 `destination-out` tool-5 Ink。

## 原版证据更正

- `dh5` 中普通 Ink 落笔走 `new wc(..., 2)`，并立即要求出现 CREATE_INK。
- 工具为 partial eraser 时，`dh5` 改走 `new jt1(...)`，不是普通 CREATE_INK 提交分支。
- `jt1` 调用 `n8j.e(...)` 与 `o8j.a(...)` 计算每个源 Ink 的零至多个几何残片；源 Ink 进入删除集合，
  残片进入 replacement map，最后交给 `new wc(..., 3)`。
- `o8j.a()` 为每段保留区间重新创建 Ink，并按路径比例重算 AudioLinked Ink 的开始时间与持续时间。
- `wc` mode 3 创建残片、替换 Group member/处理空 Group、调用 `u5j.l(...)` 删除源实体，并通过
  `oqi.a(...)` 结束 transient interaction。

完整 APK 哈希、fallback 文件哈希、命令与最小摘录见
`docs/migration/evidence/original-partial-erase-entity-replacement-jadx-2026-08-15.md`。

## 被废止的决策

以下 Phase 108 决策不再作为本地 authoring 契约：

- 每次局部擦除创建一条永久 fixed-width tool-5 Ink；
- 通过整页 `OffscreenCanvas` 与 `destination-out` 让该实体持续擦除较早元素；
- 以 ADD_STROKE 历史和对该 tool-5 Ink 的 DELETE_ENTITIES 实现 Undo/Redo；
- 无 canonical reservation 时继续写入同类永久 mask 实体。

这些做法会让擦除效果依赖永久图层顺序，与原版的实体替换、Group 维护、音频区间和搜索快照语义不一致。

## 仍保留的兼容能力

- CREATE_INK tool 5 的 decoder、模型字段与 renderer 继续保留，用于读取历史/外来 operation；不能因为本地
  writer 改为实体替换就把已有数据降级或丢弃。
- partial eraser 不应整删 Shape/Text/Image/Math；对象删除仍只属于 whole eraser。Shape/Pencil/custom outline
  的精确 partial clipping 必须按各自原版路径实现，不能用中心线近似破坏内容。

## 替代决策

本地 partial eraser 的当前决策、事务边界、Undo/Redo 和剩余范围统一见
`docs/migration/adr/ADR-0214-original-partial-erase-entity-replacement.md`。

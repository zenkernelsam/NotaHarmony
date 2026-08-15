# ADR-0214：本地 partial eraser 必须以 Ink 残片替换源实体

## 状态

Accepted，2026-08-15。取代 ADR-0085。

## 问题

Harmony 曾把一次本地 partial-erase 手势写成永久 CREATE_INK tool 5，并依赖 `destination-out` 与整页
OffscreenCanvas 维持擦除效果。该模型有四个根本偏差：

1. 擦除结果依赖永久图层与后续 z-order，而不是当前页面真实实体集合；
2. Undo/Redo 操作的是 eraser mask，不是原版的“恢复 source/隐藏 remnants”；
3. 被切开的 AudioLinked Ink 残片错误继承完整录音区间；
4. search、快照、Group member 与原版协作 operation 无法表达同一结果。

## 原版证据

- `dh5` 的普通 Ink 落笔走 `new wc(..., 2)` 并检查 CREATE_INK；partial eraser 则启动 `new jt1(...)`。
- `jt1` 通过 `n8j.e(...)` 与 `o8j.a(...)` 得到每个 source Ink 的零至多个残片，将 source 加入 deletion set、
  残片加入 replacement map，最后调用 `new wc(..., 3)`。
- `o8j.a()` 为每个几何区间重新调用 `u5j.g(...)` 创建 Ink，并按区间比例计算 AudioLinked start/duration。
- `wc` mode 3 创建残片、替换 Group member/处理空 Group、用 `u5j.l(...)` 删除 source 并以 `oqi.a(...)`
  结束 transient interaction。
- 证据文件：
  `docs/migration/evidence/original-partial-erase-entity-replacement-jadx-2026-08-15.md`。

## 决策

1. 本地 partial erase 对当前可安全中心线裁剪的普通 Ink 产生 `source → remnants[]`；source 可以被完全擦除，
   因而 remnant 数量允许为零。
2. 每个 remnant 是新 Ink 实体，不是 tool-5 mask：保留 source transform、render registers、ink effects，
   `inkEffectPhase` 按残片路径起点平移，并按 source 路径比例重算 AudioLinked interval。
3. canonical original source 必须在一个外层事务内：
   - 为每个 remnant 分配新 operation identity 并写 CREATE_INK；
   - 使用 source Ink z-index 编码 remnant；
   - CREATE_INK 共用未 flush 的 page mutation batch；
   - 最后用一次 DELETE_ENTITIES 隐藏全部 source，让页面 revision 只增加一次；
   - 同一事务重建本地 snapshot、search state 和专用历史 operation。
4. 新增 `ORIGINAL_PARTIAL_ERASE` 持久历史类型。Undo/Redo 各用一次 visibility operation在 source 与
   remnants 之间切换，每次只推进一个 revision，并从专用 page mutation 恢复为一个历史边界。
5. UI 只有在 source 全部仍是当前 canonical Ink、页面 generation 未变化且 reservation epoch 有效时才进入
   original transaction；失败时回退到同一实体替换的本地快照路径，不再写永久 mask。
6. 本地 fallback 历史必须记录：source 原索引、remnant 目标索引、每个 source 的 remnant 数量。Redo 按记录
   索引插回残片，元素顺序用 source→remnants map 重建；不能把全部 remnant `concat` 到 stroke 数组尾部。
7. source/remnant ID 必须全局互斥；history mutation 的 before+after 数量不得超过单个 type-25 visibility
   payload 的 10,000 实体上限。
8. 历史/外来 CREATE_INK tool 5 仍可解码和渲染。兼容 reader 与本地 writer 的最终表示是两个不同契约。

## 结果

- 页面快照、搜索与协作 operation 都直接看到真实残片和 source tombstone，不再依赖离屏擦除图层。
- Undo/Redo、重启后的持久历史和事务回滚使用同一实体可见性模型。
- AudioLinked Ink 的播放区间随残片几何收窄，不会重复播放整条 source Ink 的录音区间。
- fallback Undo/Redo 可保持残片位于被替换 source 的原位置，并拒绝损坏的索引、计数或身份元数据。

## 后续修订

- Group member replacement、空 Group 递归删除及相应持久 Undo/Redo 已由 ADR-0215 / Phase 238 补齐。

## 边界

- Shape partial erase、Pencil/custom/fill outline 精确 clipping 尚未实现；当前不会用中心线近似破坏这些实体。
- transient preview/end 的完整原版协议尚未闭环。
- 真机仍需验证高速手势、端点、极短残片、复杂 transform、录音同步和跨 Group 场景。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium。

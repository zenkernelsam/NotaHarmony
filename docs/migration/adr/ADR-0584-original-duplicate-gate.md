# ADR-0584 — DUPLICATE 无门槛；>=2 门槛属 GROUP（dhb case 序即 dsc ordinal）

- 状态：Corrected（修正）
- Phase 615；对齐 `dhb` case3/case4、`vsc`、`lg2.b`
  （decompiled_1.0.3）。

## 背景

本 ADR 初版将 `dhb` case4 的 `A1.size() >= 2` 门槛挂到
DUPLICATE。复查 `dsc` 枚举序后确认 case 号即 ordinal：

- `dsc.java:31-43`：STYLE=0, COPY=1, CUT=2, **DUPLICATE=3**,
  **GROUP=4**, UNGROUP=5。
- `dhb` case3（DUPLICATE）：`vsc(..., z7 ? 1 : 0)` →
  `vsc.I=1` → `lg2.b`（`vsc.java:66-72`）。
- `dhb` case4（GROUP）：`ftc` 限定 + `A1=T1(ftc.q)+组id
  size>=2` + `kk9` 建组协程 + 清选区（`dhb.java:17638-17654`）。

`lg2.b`（`lg2.java:171-191`）= `g()` 构建剪贴板负载 →
`fvb.a()` 清选区 → `e()` 就地应用负载（粘贴即重选），对
任意 `ktc` 生效——`itc` 单元素、`gtc` 单组均可 DUPLICATE，
**无数量门槛**。`>=2` 门槛属于 GROUP 建组，Harmony 的
`selectionCanGroup = authoringMembers >= 2` 本就已等价
（`resolveOriginalGroupAuthoringMembers` 即 `T1(ftc.q)+组id`
等价集）。

## 决策

撤销初版实现：DUPLICATE 菜单恢复无条件 push，
`duplicateSelected` 恢复无入口门槛，`selectionCanDuplicate`/
`canDuplicate` 移除。GROUP 门槛维持既有实现不动——它本就与
case4 一致（含 `allCanonicalOperationIds` 的已登记适配）。

## 边界

- 单元素/单组 DUPLICATE：原版 `lg2.b` 正常执行（`lg2.g`
  对 `itc.h()`/`gtc.h()` 均返回成员集），Harmony 对齐放开。
- `lg2.g` 返回 null（全锁等）→ `lg2.b` 中止；Harmony
  `copySelectedToClipboard` 同样 null 短路，一致。
- DUPLICATE 走内部剪贴板+粘贴的既有适配不变。

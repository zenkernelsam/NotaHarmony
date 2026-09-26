# Phase 865 证据 — 序列位置标识契约（cxc/exc + nti 构造 + oz9/v09）

## 目的

Phase 864 登记了物化层骨架；本阶段登记其底层的**序列位置标识** —
— `cxc` 12 字节内联结构、`exc` 比较器（含反直觉的 index 倒序
tie-break）、`nti.f/g` 构造函数，以及 `oz9`/`v09` 两个枚举。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `cxc` — 12 字节位置结构（`xwd` 内联 struct）

| 偏移 | 类型 | 读取器 | 含义 |
|------|------|--------|------|
| +0 | u16 | `c()` short | site（op 的站点） |
| +2 | — | （pad，`nti.f` 的 `s(2)`） | 对齐填充 |
| +4 | u32 | `d()`/`a1()` int | timestamp |
| +8 | u32 | `C()` int | op 内序号（pageInPayload 等） |

### `nti` 构造函数

```java
public static cxc f(short site, int ts, int index) {
    aVarA.t(4, 12);      // struct: align 4, size 12
    aVarA.w(index);      // @8
    aVarA.w(ts);         // @4
    aVarA.s(2);          // pad @2
    aVarA.y(site);       // @0
    ...
    ybg.c(cxcVar);       // ka4 校验
}
public static cxc g(qo5 opId, int index) { return f(opId.c(), opId.d(), index); }
```

`wz9` PageImpl 用 `nti.g(uq9.l(), pageInPayload)` 由「归属 op-id
+ op 内序号」派生页面位置 —— 全局全序但同 op 内按序号区分。

### `exc.A0` — 位置比较器（反直觉 tie-break）

```java
default int A0(exc other) {
    int iA1 = a1() - other.a1();            // timestamp：Java int 减法（可回绕）
    if (iA1 != 0) return iA1;
    int iM = (m() & 65535) - (other.m() & 65535);   // site：按无符号 u16
    return iM != 0 ? iM : other.C() - C();          // index：**倒序**（other−this）
}
```

三级排序：timestamp 升序（int 减法语义）→ site 升序（u16）→
**index 降序**。最后一项 `other.C() - C()` 是刻意倒序，是
典型的移植陷阱（升序写法会翻转同 op 内的实体顺序）。

### `oz9` / `v09` 枚举

- `oz9`：`{UNBOOKMARKED=0, BOOKMARKED=1}` —— bookmark 寄存器取值；
  `wz9.l` = `winner == BOOKMARKED`。
- `v09`：`{ANIMATION=0, INK=1, SHAPE=2, BLOCK=3}` —— 实体种类；
  `ly3.e()/f()` 返回（`f()` 用于 pre-materialize 待定类型）。

## Harmony 侧（`note/src/main/ets/data/OperationIdentity.ets`）

已完整移植：

- `OriginalSequenceIdentity` = `{timestamp, siteId, index}` —— cxc 三元组。
- `encodeOriginalSequenceId` → `seq:<ts>:<site>:<index>`（hex）。
- `compareOriginalSequenceIdentity` —— 注释即引 `exc.A0`：
  `toJavaInt(ts) 减法 | 0`（保留 Java int 回绕）→ site u16 升序 →
  **`right.index - left.index` 倒序**，与原版逐项一致。
- `encodeOriginalPageStorageId` → `original-page:<len>:<noteId>:seq:…`
  —— 页面存储主键携带来源位置。
- 赢家寄存器：`bookmarkWinner`（ts+site）持久化为
  `winner_timestamp`/`winner_site_id` 行 —— oz9 语义等价；
  实体种类由 op payload 类型与 `original_*_state` 表覆盖（v09 四类
  均有对应状态表/编码器）。

## 结论

cxc/exc 契约（12 字节布局、nti.f/g 构造、ts→site→index-desc
比较器）在 Harmony 由 `OriginalSequenceIdentity` 全等价落地，
含 Java int 回绕与倒序 tie-break 两个易错点。oz9/v09 语义由
bookmarkWinner 与实体状态层覆盖。本阶段纯文档+fixture，无源改动。

# Phase 866 证据 — 赢家寄存器契约（fqb/do6/xj2 + so5.a + fsi.J）

## 目的

Phase 864/865 登记了物化层与位置标识；本阶段登记寄存器的
**LWW 冲突解决核心**：`fqb` 赢家单元、`do6` 包装、`xj2` 读侧
助手、`so5.a` op-id 比较器、`fsi.J` 挂钟提取。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `fqb` — 赢家寄存器单元（builder/cell）

```java
public final class fqb {
    public qo5 a;    // 赢家 op-id（null = 空寄存器）
    public Object b; // 赢家值
    public xgb c;    // 赢家挂钟

    public fqb(yc6 reg) { a=(qo5)reg.J; b=reg.K; c=(xgb)reg.L; }  // 解冻读
    public yc6 a()    { return new yc6(a, b, c, 14); }            // 冻结回 yc6-14
    public boolean b(){ return a != null; }                       // 已有赢家

    public void c(uq9 op, Object value) {                         // LWW 提议
        qo5 id = op.l();
        if (a == null || so5.a(id, a) > 0) {  // 新 op-id 更大 → 覆盖
            a = id; b = value; c = new xgb(fsi.J(op));
        }
    }
}
```

`yc6` discriminant-14 形态即寄存器：`J`=赢家 opId、`K`=赢家值、
`L`=赢家 xgb 挂钟 —— 与 864 确认的 `.K` 读槽一致。

### `do6.g(yc6, yc6)` / `xj2` 读侧 / `vz9`

- `do6.g(reg, reg)`：`vz9` Page builder 用它把 `wz9` 三个寄存器
  包成可变 builder；`build` 时 `a()` 冻结回新 `wz9`。
- `xj2.k(yc6, obj)`：寄存器非空则包 `fqb`，否则建空寄存器
  （`yc6(null, obj, null, 14)` —— 预填初值、无赢家）。
- `xj2.v(yc6, fl6)` = `yc6.K`；`xj2.w(fqb, fl6)` = `fqb.b` ——
  读侧统一返回赢家值。

### `so5.a` — op-id 比较器（寄存器排序键）

```java
static int a(qo5 l, qo5 r) {
    return l.d() == r.d()
        ? ba6.w(l.c() & 65535, r.c() & 65535)   // site u16 无符号比较
        : Integer.compareUnsigned(l.d(), r.d()); // ts u32 **无符号**比较
}
```

区别于 `exc.A0`：无 index 项、timestamp 用**无符号**比较
（`exc.A0` 用有符号回绕减法）。两个比较器职责不同：
`so5.a` 用于 op-id 赢者判定；`exc.A0` 用于 cxc 位置排序。

### `fsi.J(uq9)` — op 挂钟

```java
tmf n = op.n();          // serverTime 结构
return n != null ? n.I : op.k();   // 优先 serverTime，否则 clientTime
```

寄存器 `xgb` 记录赢家 op 的挂钟（serverTime 优先），供
冲突诊断/展示；**比较本身只看 op-id，不看挂钟**。

### `fsi.K(uq9)` — op 触及实体清单

按 `uq9.m()` payload 类型分派（case 0-5,15,...），返回该 op
涉及的实体 id 列表 —— 供依赖追踪/删除传播。

## Harmony 侧

- `compareOperationIdentity`（`OperationIdentity.ets`）：
  JS number 0..2^32-1 比较 = `Integer.compareUnsigned` 等价；
  site u16 同序 —— 与 `so5.a` 逐项一致。
- 赢家行物化（`OriginalNoteBundlePageIdentity`）：每字段持久化
  `{value, winner_timestamp, winner_site_id}` —— fqb 的
  {value, winnerId} 持久化形态；`compareOperationIdentity > 0`
  才覆盖 = `fqb.c` 的 `so5.a > 0` 语义。
- 原版 `xgb` 挂钟为辅助信息，非排序键 —— Harmony 不落盘等价。

## 结论

寄存器 LWW 契约（提议即比较 op-id、胜者覆盖、op-id 用无符号
ts+site 排序、挂钟仅辅助）在 Harmony 由 winner_* 持久化列 +
compareOperationIdentity 等价覆盖。本阶段纯文档+fixture。

# Phase 1089 证据 — exc 文本锚点 + 序列 CRDT 全序

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `exc` = 文本锚点（Comparable，3 键全序）

```java
default int A0(exc o) {
    int d = a1() - o.a1();              // ① anchor key
    if (d != 0) return d;
    d = (m()&0xffff) - (o.m()&0xffff);  // ② site (无符号)
    if (d != 0) return d;
    return o.C() - C();                 // ③ seq（注意反向！）
}
int C(); int a1(); short m();
```

- `{a1:int 锚键, m:short site, C:int 序列}` 三元序。
- **③ C() 反向**（`o.C()-C()` 而非 `C()-o.C()`）——同 site
  同键时新者靠前（插入偏序）。
- 与 `qo5`/`so5.a`（Phase 1063）的 (lt,site) 序同模式但
  第三键方向相反。

## `kci.b(exc, str, qo5) → f46` = INSERT_STRING 构建

- slot0 `sg5.f(exc)` 位置；slot2 `rh8.O(qo5)` 文本域。

## `kci` = mega-merge（音频表 + Compose + op 构建）

## Harmony 决策

- 文本锚点三元序：(a1, site, -C)；C 反向 = 新插入靠前。
- INSERT 经 `kci.b` 构 f46。

## 产出

- fixture `d02-text-anchor.mjs`（10 断言）。
- ADR-1033；中文报告。

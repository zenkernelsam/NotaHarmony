# Phase 1107 证据 — i4c/h4c 应用记录 + uwc 定位文本元素

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `i4c` = 应用结果接口

`e4c.b(uq9)` 的返回类型 —— op 应用记录。

## `h4c implements i4c` = 应用记录

```java
class h4c implements i4c {
  ywc a;    // 定位元素
  qo5 b;    // opId
  qo5 getId() → b;
}
```

## `uwc extends ywc` = 定位文本元素记录

```java
uwc { Object b;      // 载荷（CharSequence/byte[]）
      qo5 c;         // opId
      exc d;         // 锚点
      long e, f;     // 时戳（serverTime / seq）
      Integer g }    // 位序
```

`e4c.b` case7 构造：`uwc{length包装, uq9.l()=opId, e46.j()=cxc位置,
fsi.J(op)=时戳, tmf?:op.k()=序列, e(e4c,cxc)=位序}`。

## `njj.L`/`njj.y` = 锚导航辅助

`e4c` 内用于 `iwc`/`qwc` 序列树上的锚点查找（`d(new hr5())` 派生）。

## `xj2.f(exc, map)` = tombstone 存在判定

## Harmony 决策

- 文本应用记录 = `{ywc 元素, opId}`；定位元素携带
  `{opId, exc锚, 双时戳, 位序}`。
- 应用结果接口化（i4c），具体记录 h4c。

## 产出

- fixture `d02-text-records.mjs`（10 断言）。
- ADR-1051；中文报告。

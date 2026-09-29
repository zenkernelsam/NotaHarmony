# Phase 1093 证据 — hvd FlatBuffers 向量→只读 List 适配

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hvd implements List, ik6` = FB 向量只读 List 适配器

```java
{cee I(载荷), cxc J}
add/addAll/… → throw "read-only collection"
g2c extends hvd{f2c}   // REVIVE_CHARS 向量→List
```

- 把 FlatBuffers 表内向量包装成 Java `List`；
  `ik6` = Kotlin 只读集合标记；写全抛异常。
- 元素经 `cee` slot 读物化。

## `m2 implements Collection, ik6` = 只读集合基

`y3 extends m2`；add/addAll 抛 `UnsupportedOperationException`。

## `ywc`/`xwc`/`hvd`/`m2` 定位元素与只读适配谱系

## Harmony 决策

- FB 向量→只读 List 适配保留；应用层只读。
- `m2`/`y3` 只读集合基。

## 产出

- fixture `d02-fb-list.mjs`（10 断言）。
- ADR-1037；中文报告。

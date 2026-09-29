# Phase 1038 证据 — ze9 bundle 头模型 + a79 常量注册表

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ze9 implements ye9` = bundle 头模型

```java
public final class ze9 implements ye9 {
    public final ttf a;    // noteId
    public final ttf b;    // ?
    public final short c;  // schemaVersion
    public final ttf d;    // ?
    public final long e;   // timestamp
    public final ttf f;    // ?
}
```

- 6 字段头记录——对应 `m09.a` 物化器的
  `ze9(r4j.b, r4j.c, r29.l(), r0(r29.m()), r29.j(),
  r0(r29.k()))`：noteId+?+schemaVersion+?+
  timestamp+?。
- `ye9` = 头 iface。

## `a79` = 常量注册表

- `er6 L = new er6(3)`（文档主常量）；
  `qed N`（默认 size）；`float P`；
  `w69 R` + `y69`/`v69`/`z69` 协程 helpers。
- 大 utility/registry——文档默认+协程辅助。

## `r4j.b/c` + `r29` 访问器

- `r4j.b(r29)`/`c(r29)` = bundle id 提取；
  `r29.l/j/k/m()` = 头字段访问器。

## HarmonyOS 决策

`ze9` 头模型保留（六字段记录）；`a79` 常量注册表
移植；r29 访问器语义保留。

## 产出

- fixture `d02-ze9-header.mjs`（10 断言）。
- ADR-0982；中文报告。

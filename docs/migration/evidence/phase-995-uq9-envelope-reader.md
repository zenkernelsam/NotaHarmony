# Phase 995 — `uq9` Op 信封完整访问器表（读侧）

来源：`decompiled_1.0.3/sources/defpackage/uq9.java`

## 1. 七字段访问器（vtable 槽 = 4+2×fieldIndex）

| 方法 | 槽 | 字段 | 类型 | 缺省/必需 |
|------|-----|------|------|-----------|
| `p(qo5)`/`l()` | 4 | f0 id | qo5 内联 struct | **必需**（iC==0→`o14.i` "No value for (required) field id"） |
| `k()` | 6 | f1 clientTime | long | 0 |
| `n()` | 8 | f2 serverTime | tmf | null |
| `j()` | 10 | f3 audioTime | tmf | null |
| `m()` | 12 | f4 payloadType | byte→haa | 越界→**ordinal0 NONE** |
| `q(cee)` | 14 | f5 payload | cee 表 | —（uoffset） |
| `r(sdf)`/`o()` | 16 | f6 transientInteraction | sdf | 0→null |

与 `zq9.d` 写序严格镜像（Phase 964：f0 id req +
f5 payload req）。

## 2. `m()` = byte→haa 带界回退

```java
byte b = slot?J.get:0;
i = (b&0xFF) - haa[NONE].I;   // I=byte ordinal
return (i<0 || i>=entries.d()) ? entries.get(0) : entries.get(i);
```

**越界字节 → NONE**（随后 `z5c.x` NONE→fail-loud）——
未知 op 类型安全降级为先识别再报错，两阶段。

## 3. `uq9 implements ka4`

`a()` = 验证描述（ka4 契约；Phase 977）。

## 4. `equals/hashCode`

对象级（`cee` 缓冲比较——`J`/`I` 位置等式）。

## 5. Harmony 对齐

等价：七字段访问表 + byte→enum 界回退→NONE。

## 6. 验证

`d02-uq9-envelope-reader.mjs` 静态断言。

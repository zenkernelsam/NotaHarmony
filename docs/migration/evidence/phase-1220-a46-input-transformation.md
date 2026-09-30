# Phase 1220 证据 — a46 = InputTransformation 链（实名泄漏）

来源：`defpackage/{a46,bg4,d28,nv1,z36}.java`。

## `a46` = Compose `InputTransformation` iface

```java
interface a46 {
    default void h(xvc);       // 语义回调
    void i(dle);               // 变换编辑缓冲
    default nn6 j() → null;    // KeyboardOptions 合并
}
```

## 4 实现（实名/行为泄漏）

| 类 | 真实角色 |
|---|---|
| `bg4` | **`.then` 链** — `a.i(dle)` → `b.i(dle)`，<br>`toString` = `"a.then(b)"`；`j()` 合并 nn6 |
| `d28` | **`InputTransformation.maxLength(6)`** —<br>`toString` 实名泄漏！`len>6` 时 `c(0,len,原文)`+`f(sel)`+`w()` 回滚拒绝 |
| `nv1` | **hex 颜色过滤器** — `#` 前缀检查 +<br>`0-9a-fA-F` 逐字符校验（非法→回滚） |
| `z36` | 空变换（passthrough） |

## `i(dle)` 拒绝语义

```java
dleVar.c(0, length, eleVar.K.toString());  // 恢复原值
dleVar.f(eleVar.L);                        // 恢复选区
dleVar.a().w();                            // 放弃本次编辑
```

= 校验失败→**编辑回滚**（拒绝非法输入）。

## 与文本管线关系

`qoe.a` → `a46.i(dleVar3)` 变换链过滤 → `qoe.e`
应用 → `ele` 新态 —— `a46` 是输入过滤器层
（限制长度/字符集），不是 CRDT sink 本体；文档
写入经 `e4c` ops（Phase 1130-1135）。

## Harmony 决策

`InputTransformation` 链 → Harmony `onWillChange`/
输入过滤器（`then` 组合 + `maxLength` + 字符集校验 +
回滚拒绝）。

## 产出

- fixture `d02-a46-input-transformation.mjs`（10 断言）。
- ADR-1164；中文报告。

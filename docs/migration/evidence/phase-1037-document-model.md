# Phase 1037 证据 — x09 文档模型 + m09 默认常量

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `x09` = 文档模型标记接口

```java
public interface x09 {
    public static final m09 a = m09.a;  // companion
}
```

- 裸 marker——218+ impl 类实现此接口
  （所有文档模型实体）。

## `m09` = companion/默认常量持有器

```java
public final class m09 {
    static final qed b = a79.N;        // 默认 size
    static final double c = qed.d()/768.0;  // 缩放因子
    static final vy7 d = a79.O;        // 默认 margins
    static final hu1 e = tu1.a lazy;   // 默认 color
    static final nz9 f = vv7.f(...);   // 默认 ?
    static final float g = a79.P;
}
```

- 默认文档参数：size `qed`、margins `vy7`、
  color `hu1`、还有 `vv7` 复合默认 + `a79.P` float。
- `c = qed.d()/768.0` = 基准高 768 缩放。

## `m09.a(r29, cl9)` = bundle→model 物化器

```java
ze9 ze9Var = new ze9(r4j.b(r29), r4j.c(r29),
    r29.l(), m18.r0(r29.m()), r29.j(),
    m18.r0(r29.k()));
List ops = lv2.T(r29);   // ops 物化
for (obj : ops) { ... }  // 逐 op 应用
```

- `r29` NoteBundle → `ze9` 头部 + `lv2.T` ops →
  `cl9` 文档模型 —— **load 侧物化器**。

## `a79`/`tu1` = 常量/颜色注册表

- `a79.L/N/O/P` = 全局默认值注册表；
- `tu1.a` = hu1 默认颜色的 lazy。

## HarmonyOS 决策

`x09` marker→ArkTS base interface；`m09` 默认常量
+ `a(r29)` 物化器保留；768 缩放因子对齐。

## 产出

- fixture `d02-document-model.mjs`（10 断言）。
- ADR-0981；中文报告。

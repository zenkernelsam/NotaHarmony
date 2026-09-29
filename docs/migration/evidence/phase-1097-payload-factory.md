# Phase 1097 证据 — z5c.x 载荷工厂 + uq9.q 缓冲绑定

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `z5c.x(uq9) → cee` = op→载荷工厂

```java
switch (op.m().ordinal()):
    case 0 (NONE): rgc.b("uq9"); throw null   // 报错+unreachable
    case 1: new l2d(); break;                 // SET_METADATA
    case 2: new ra0(); break;                 // ASSET_PERSISTED
    case 3: new ln2(); break;                 // CREATE_PAGE
    …                                         // 全 32 序位
    default: o14.t(); return null;
uq9Var.q(payload);                            // ← 绑 op 缓冲
return payload;
```

- **两段式**：先 `new X()` 空载荷表，再 `uq9.q(payload)`
  把 op 的 FlatBuffers 缓冲绑进去（`cee.d()` 定位）。
- `q` = op 包络→载荷缓冲绑定方法（uq9 实例方法）。

## 与 Phase 1044/1096 关系

`z5c.x` = 序位→类（反序列化）；`zq9.a` = 类→序位（序列化）。

## Harmony 决策

- 载荷解码 = `new + bind` 两段；NONE/default fail-loud
  （rgc.b / o14.t）。

## 产出

- fixture `d02-payload-factory.mjs`（10 断言）。
- ADR-1041；中文报告。

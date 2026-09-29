# Phase 1094 证据 — Kotlin Function* 层（xx4/ix4/wx4/kkf/mha）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 函数接口族（Kotlin `FunctionN` vendored）

| 类 | 角色 |
|----|------|
| `xx4` | Function 基接口（`getArity()`） |
| `ix4 extends xx4` | **Function1**：`Object invoke(Object)` |
| `wx4 extends xx4` | **Function2**：`Object invoke(Object,Object)` |
| `t42` | type-token iface |
| `kkf.w(int, ix4)` | arity 校验/适配 |

## `ba6.L(wx4, ix4) → mha`

```java
as0 s = new as0(wx4, 4);         // Function2 包装
kkf.w(1, ix4);                    // ix4 arity=1 校验
return new mha(7, s, ix4);        // mha{int, as0, ix4}
```

`mha` = Flow/通道包装（`ba6.L` 构建 Flow-transform 管道）。
`as0` = Function2→特定形态适配。

## 与 Phase 1035/1036 衔接

`wx4`/`ix4`/`xx4` = `FunctionN` 族（1036 的 `n8e`/`wx4`
suspend-lambda 基础的姊妹层）；`mha` = coroutines Flow。

## Harmony 决策

- lambda = 类型化 `FunctionN`（invoke 签名 + arity）。
- Flow/transform 用 `mha` 包装。

## 产出

- fixture `d02-function-types.mjs`（10 断言）。
- ADR-1038；中文报告。

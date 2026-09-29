# Phase 1036 证据 — 续体/lambda 原语 + asd StateFlow

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 续体/lambda 族

| 类 | 角色 |
|---|---|
| `ff2` | `abstract extends lr0` =
  **BaseContinuationImpl**（suspend 续体基类） |
| `n8e` | `extends ff2 implements hy4` =
  **SuspendLambda**（`getArity`+n 参数） |
| `wx4` | `interface extends xx4` =
  **FunctionN**（可变参数 lambda iface） |
| `lr0` | Continuation 最底层 |
| `hy4` | arity-marker iface |

## `asd` = **MutableStateFlow**

```java
public final class asd extends o5
    implements hl8, ml4, cz4 {
    public static final AtomicReferenceFieldUpdater N =
        ARFU.newUpdater(asd.class, Object.class,
                        "_state$volatile");
    public int M;                  // 序列号
    public asd(Object obj);        // 初值
}
```

- `_state$volatile` ARFU + `int M` 序号 =
  **StateFlow 状态槽**——StateFlow 的 CAS-on-state。
- `ml4`/`cz4` 复用：StateFlow⊂SharedFlow。

## `o5`/`hl8`

- `o5` = StateFlow impl 基类；`hl8` = StateFlow
  iface（MutableStateFlow）。

## 全图

- `ff2`/`n8e`/`wx4` = suspend/lambda 基建；
- `asd`/`sfb`/`ml4`/`cz4` = Flow 基建；
- `pce`/`cx6` = Lazy 基建；
- `em8`/`fm8` = Mutex 基建。

## HarmonyOS 决策

- `asd` StateFlow→ArkTS `@State`/`@Observed`（
  响应式状态）；StateFlow 的 value 语义保留。
- `ff2`/`n8e`/`wx4`→ArkTS async/await+函数类型。

## 产出

- fixture `d02-stateflow-lambdas.mjs`（10 断言）。
- ADR-0980；中文报告。

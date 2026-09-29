# Phase 1035 证据 — Kotlin 协程原语（sfb/ml4/em8/fm8）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## Flow 族

| 类 | 角色 |
|---|---|
| `sfb` | `implements s7d, ml4, cz4` =
  **MutableSharedFlow**（`v7d I` 委托） |
| `ml4` | `b(yh2,int,w41)` collector ——
  **SharedFlow 接口**（修正 1019 的"会话状态
  iface" 误判） |
| `s7d` | `ml4` 的父 —— MutableSharedFlow 上层 |
| `cz4` | FlowCollector iface |
| `v7d` | sfb 的 delegate（sharedFlow impl） |

## Mutex 族

| 类 | 角色 |
|---|---|
| `em8` | `extends bwc implements cm8` = **Mutex**
  ——`AtomicReferenceFieldUpdater P` on
  `owner$volatile`（owner CAS） |
| `fm8` | `a() → em8` + `f02 a = NO_OWNER` —
  Mutex 工厂 |
| `bwc` | Mutex 基类 |
| `cm8` | Mutex iface |

## 修正记录

| Phase | 误 | 实 |
|---|---|---|
| 1019 | `ml4` = 会话状态 iface | **`ml4` = SharedFlow**
  （Kotlin coroutines） |
| — | `sfb` | MutableSharedFlow |
| — | `em8`/`fm8` | Mutex/Mutex 工厂 |

## 普及度

- `sfb`/`ml4`：nr1 三 Flow（j/k/l）、`vmc` 索引流、
  `vs4` 遥测 Flow——**全是 SharedFlow**。
- `em8`/`fm8`：`b50`/`nr1` 的 Mutex。

## HarmonyOS 决策

- `sfb`/`ml4` → ArkTS EventEmitter/observed 属性
  （@Observed/@Track）——Harmony 无 Flow；
- `em8` → ArkTS async lock（单线程事件循环
  简化——仅防 reentrancy 不需真锁）。

## 产出

- fixture `d02-coroutine-primitives.mjs`（10 断言）。
- ADR-0979；中文报告。

# Phase 1204 证据 — t76 事件 8 消费方角色

来源：`defpackage/{ls,n03,e71,of1,ot3,j5j,em1,ww0,ol4}.java`。

## `ol4` = Kotlin `FlowCollector`

```java
interface ol4 { Object emit(Object, ef2); }
```

`t76` 事件经 `wj8` drop-oldest 通道（Phase 1201）→
`ol4.emit` Flow 收集器分发。

## 消费方角色表

| 类 | 角色 |
|---|---|
| `ls implements ol4` | **MotionEvent↔StrokeInput 对账器** — `ueg.e` StrokeInput 池、`o14.s("Stroke ID ... was started with a MotionEvent but finished with a StrokeInput")` 生命周期错配告警；`ClipData.newPlainText("link")` 链接粘贴 |
| `n03 implements ol4` | `t76` instanceof 分发收集器（`e14`/`ht9` 次派发） |
| `e71 implements ol4` | 双实例（switch 0/1）add/remove `ekd` 手势列表 |
| `ww0` | **触觉反馈栈** — 栈顶手势→`0.08/0.10/0.16` 权重（Phase 1202） |
| `of1` | 事件类型归并（`fwa/rj5/zo4/mn3` 分类） |
| `em1` (abstract) | Compose `@Composable` 宿主（`uz4` composer + 位掩码参数 + `fag.h(2,8f)`） |
| `j5j` (abstract) | Compose 内部类（classes3.dex） |
| `ot3` (abstract) | **Material 动效令牌**：`vhf`=TweenSpec(120ms/150ms) + `iq2`=CubicBezierEasing(0.4,0,0.6,1) — 标准缓动 |

## 判定

`t76` = 编辑器手势事件总线；消费方分两类：
**应用层手势机**（`ls`/`n03`/`e71`/`ww0`/`of1` — 笔迹
对账/触觉/手势栈）与 **Compose 框架层**（`em1`/`j5j`/
`ot3` — composable 宿主 + Material 动画缓动规格）。

## Harmony 决策

- `ol4`/`ef2` Flow 收集 → Harmony 事件订阅回调。
- `ls` StrokeInput 对账 → Harmony 笔迹输入校验
  （MotionEvent↔点序列一致性，对齐 Phase 1203
  自研 StrokeInputBatch）。
- `ot3` TweenSpec/cubic-bezier → Harmony `curves`
  （`cubicBezierCurve(0.4,0,0.6,1)` + 120/150ms 动画）。

## 产出

- fixture `d02-t76-consumers.mjs`（10 断言）。
- ADR-1148；中文报告。

# Phase 1202 证据 — t76 编辑器手势事件族（12 impl + hwa 子族）

来源：`defpackage/{t76,rj5,sj5,zo4,ap4,mn3,nn3,ln3,ll3,ml3,hwa,fwa,gwa,ewa,ww0,e71,ls,n03,of1,ot3}.java`。

## t76 = 手势/指针事件标记接口

`wj8`（Phase 1201）经 `Channel(0,16,DropOldest)` 派发 `t76`；
8 个消费方（`ww0`/`e71`/`em1`/`j5j`/`ls`/`n03`/`of1`/`ot3`）
各自按 `instanceof` 分发。

## 事件族（12 实现）

| 事件 | 结构 | 角色 |
|---|---|---|
| `rj5` | 空标记 | 指针-down（触觉权重 **0.08**） |
| `sj5{rj5}` | 包装 | rj5 结束（remove 包裹的 down） |
| `zo4` | 空标记 | 指针-down（权重 **0.10**） |
| `ap4{zo4}` | 包装 | zo4 结束 |
| `mn3` | 空标记 | 指针-down（权重 **0.16** 最强） |
| `nn3{mn3}` | 包装 | mn3 结束 A |
| `ln3{mn3}` | 包装 | mn3 结束 B |
| `ll3` | 空标记 | 独立事件 |
| `ml3{ll3}` | 包装 | ll3 结束 |
| `hwa extends t76` | 子接口 | 定时事件族 |
| `fwa{long a}` | 定时 | 手势开始（带时间戳） |
| `gwa{fwa}`/`ewa{fwa}` | 包装 | fwa 结束 A/B |

## 消费语义（`ww0` 为证）

```java
if (t76Var instanceof rj5) list.add(t76Var);
else if (t76Var instanceof sj5) list.remove(((sj5) t76Var).a);
else if (t76Var instanceof zo4) list.add(t76Var);
else if (t76Var instanceof ap4) list.remove(((ap4) t76Var).a);
else if (t76Var instanceof mn3) list.add(t76Var);
else if (t76Var instanceof nn3/ln3) list.remove(...);
t76 top = au1.o1(list);          // 栈顶 = 当前手势
if (ba6.o(d, top)) return;       // 去重
float w = top instanceof rj5 ? 0.08f
        : top instanceof zo4 ? 0.10f
        : top instanceof mn3 ? 0.16f : 0f;
```

= **多指针手势栈**：down 入栈、包装事件按引用移除
对应 down、栈顶决定当前手势→**触觉反馈强度**
（与 Phase 1197 `data/stylus/haptic` 偏好呼应）。
`e71` 以相同 add/remove 喂 `ekd` 列表（switch 0/1 双通道）；
`fwa{long}` 定时手势由 `gwa`/`ewa` 双结束变体移除。

## Harmony 决策

- `t76` 族 → ArkTS 判别联合/密封类手势事件。
- `wj8` drop-oldest 派发 → Harmony 事件队列（对齐
  Phase 1201）。
- `ww0` 触觉栈顶权重 → Harmony `vibrator` 强度映射
  （haptic 偏好 Phase 1197 对齐）。

## 产出

- fixture `d02-t76-events.mjs`（10 断言）。
- ADR-1146；中文报告。

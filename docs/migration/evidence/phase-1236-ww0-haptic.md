# Phase 1236 证据 — ww0 触觉强度动画器

来源：`defpackage/{ww0,t76,rj5,zo4,mn3,sj5,ap4,nn3,ln3,vhf,ks0,au1,ba6}.java`。

## `ww0` = 事件栈 → 触觉权重动画器

```java
// t76 事件 → 活动集
if (rj5) list.add;  else if (sj5) list.remove(sj5.a);
if (zo4) list.add;  else if (ap4) list.remove(ap4.a);
if (mn3) list.add;  else if (nn3) list.remove(nn3.a);
else if (ln3)       list.remove(ln3.a);

t76Var2 = au1.o1(list);            // 栈顶活跃事件
if (ba6.o(prev, t76Var2)) return;  // 去重

// 顶事件 → 触觉权重
f = (rj5 ? 0.08f : zo4 ? 0.1f : mn3 ? 0.16f : 0f);
// 动画规范：mn3/zo4 → vhf(45ms, ds3.c), 否则 b5c.a
vhfVar = new vhf(45, ds3.c, 2);
ks0 = xj2.A(hi2, → animate weight)  // 渐进触觉
```

## 语义

- 维护**活跃事件栈**：`rj5`/`zo4`/`mn3` down 入栈，
  `sj5`/`ap4`/`nn3`/`ln3` end 出栈（配对嵌套）；
- 栈顶事件→权重：`rj5`=`0.08` / `zo4`=`0.1` /
  `mn3`=`0.16` —— **触觉压力随手势工具分级**；
- `vhf` tween（`45ms`/`b5c.a` 默认）动画权重变化 →
  **渐进触觉压力**（笔/橡皮等触感强度随工具类型平滑
  过渡）;
- `ks0`/`wsc` = 动画 coroutine 启动。

## Harmony 决策

事件栈→权重+动画 → Harmony `vibrator`+自研 tween；
权重映射（0.08/0.1/0.16）→ 触觉强度映射。

## 产出

- fixture `d02-ww0-haptic.mjs`（10 断言）。
- ADR-1180；中文报告。

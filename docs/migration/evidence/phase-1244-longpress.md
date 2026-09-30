# Phase 1244 证据 — i2/g2/b14 长按 fire-vs-cancel 机制

来源：`defpackage/{i2,g2,b14,lh3}.java`。

## `g2` = 计时器 fire 协程

```java
g2 extends n8e { K=wj8, L=fwa;
    invokeSuspend: delay → new gwa(fwaVar)      // 计时到 → fire
}
```

## `b14` = dispose→cancel

```java
b14 implements lh3 {                         // dispose 句柄
    dispose() → new ewa(fwaVar)               // dispose → cancel
}
```

## `i2` = k2 长按状态机（双分支）

```java
i2 extends n8e { K=k2, L=fwa;
    invokeSuspend: 
        → new ewa(fwaVar)   // 提前抬起 → cancel
        → new ewa(fwaVar)   // (另一 case)
        → new gwa(fwaVar)   // 计时到 → fire
}
```

## 语义

- `gwa` = **长按计时触发**（`g2` delay-coroutine）；
- `ewa` = **提前释放/dispose 取消**（`b14.dispose`→`ewa`、
  `i2` 提前抬起→`ewa`）;
- `fwa`↔`gwa`/`ewa` 1:2 = **长按 fire-vs-release 二分** ——
  长按按住到阈值触发 `gwa`，提前松开触发 `ewa` 取消；
- `i2`/`g2`/`b14` = 计时协程 + dispose 句柄 + 状态机。

## Harmony 决策

长按计时 → Harmony `onLongPress`+`delay` 协程 +
dispose→cancel —— fire/cancel 语义保真。

## 产出

- fixture `d02-longpress.mjs`（10 断言）。
- ADR-1188；中文报告。

# Phase 1239 证据 — hwa/fwa/gwa/ewa 计时手势事件

来源：`defpackage/{hwa,fwa,gwa,ewa,t76}.java`。

## `hwa` = 计时事件子类 iface

```java
public interface hwa extends t76 {}   // 计时事件分类标记
```

## `fwa` = 计时手势 start

```java
public final class fwa implements hwa {
    public final long a;              // 时间戳/id
}
```

## `gwa`/`ewa` = 两种终态 end（包 fwa）

```java
public final class gwa implements hwa { final fwa a; }  // end-A
public final class ewa implements hwa { final fwa a; }  // end-B
```

## 语义

- `fwa` = 计时手势开始（`long a` = 启动时间戳/id）；
- `gwa`/`ewa` = **两种终态**，都包 `fwa` → `e71` 出栈
  `((gwa).a)`/`((ewa).a)` —— **长按/press-hold 计时手势**：
  `fwa` 起，`gwa`=计时触发完成 vs `ewa`=提前释放取消；
- `hwa` = 计时事件分类（区别于 `rj5`/`zo4`/`mn3` 即时
  触摸事件）;
- 计时事件也走 `ww0`/`e71` 同一栈语义（`fwa` add、
  `gwa`/`ewa` remove）。

## Harmony 决策

fwa/gwa/ewa 计时事件 → Harmony 手势回调（`onLongPress`
+计时器）→ start/cancel-vs-fire 二分终态。

## 产出

- fixture `d02-timed-events.mjs`（10 断言）。
- ADR-1183；中文报告。

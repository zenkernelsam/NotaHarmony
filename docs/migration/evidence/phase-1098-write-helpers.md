# Phase 1098 证据 — FlatBuffers 写助手 + 校验抛异常

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 结构体写入（FB struct emit）

```java
sg5.f(a, exc):                     // 12-byte exc 锚点 struct
    t(4,12); w(C()); w(a1()); s(2); y(m()); r();

rh8.O(qo5, a):                     // 8-byte opId struct
    t(4,8); w(d()); s(2); y(c()); r();
```

- `t(align,size)` = prep；`w(int)`/`y(short)` = 放标量；
  `s(n)` = short-slot；`r()` = 返回偏移。
- `exc` = `{C:int, a1:int, m:short}` 12B；`qo5` = `{d:int,
  c:short}` 8B。

## `rh8.b(int, short) → qo5` = opId 构造

## `ybg.c(ka4)` = 校验+抛异常

```java
String err = payload.a();            // ka4 校验（返回错误串）
if (err == null) return;
d(err):  log yn7.MODEL + throw ValidationException(err)
```

- 每个 op 构建后 `ybg.c` 校验 → 非空错误 → MODEL 日志 +
  `ValidationException`（fail-loud，写时校验）。

## Harmony 决策

- struct 写序 = prep+w/y/r；`ybg.c` 校验抛 ValidationException。
- 锚点 12B、opId 8B 打包布局。

## 产出

- fixture `d02-write-helpers.mjs`（10 断言）。
- ADR-1042；中文报告。

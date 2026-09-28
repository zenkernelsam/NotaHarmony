# Phase 948 证据 — `ybg` 校验驱动

## `ybg.c(ka4)`（实证，全文）

```java
String strA = ka4Var.a();          // 校验器返回错误串
if (strA == null) return;           // 合法即返
d(strA);                            // 记录
throw new ValidationException(strA);
```

## `ybg.d(String)`（实证）

```java
a.c(yn7.MODEL, str, null, null);    // MODEL 频道记日志
throw new ValidationException(str); // 硬抛
```

## 语义

- **校验契约**：`ka4.a()` null=合法 /
  错误串=非法——全模型统一（894-897 已证）。
- **失败行为**：先 `yn7.MODEL` 频道记日志，
  再抛 `ValidationException`——失败关闭，
  无静默降级。
- **调用点**：每个工厂构建后调用
  （ys2.d/`ybg.c(dm2)` 实证）+ `z5c` 分发
  （`rgc.b` 同样走 yn7 记日志后抛）。

## 结论

校验驱动=最简契约执行器：a()→日志→抛。

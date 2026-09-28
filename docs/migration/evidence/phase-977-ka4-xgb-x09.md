# Phase 977 — `ka4` 校验契约 + `xgb` Realtime + `x09` 定性

来源：`decompiled_1.0.3/sources/defpackage/{ka4,xgb,x09}.java`

## 1. `ka4` = 校验错误契约接口

```java
public interface ka4 { String a(); }
```

**所有 80 个注册表/结构类型实现 ka4**——`a()` 返
校验错误串或 null（"No value for (required) field X"
生产者）。`ybg.c`（Phase 948）消费此契约：
`a()`→非空→`yn7.MODEL` 日志→抛 `ValidationException`。

这是原版"每个线型类型自带合法性自检"的架构契约——
equals/hashCode/toString/a() 四件套为所有表标配。

## 2. `xgb` = `Realtime{value:ulong}` 值类

```java
public final long I;
compareTo → Long.compareUnsigned   // 无符号比较
toString → "Realtime(value=" + njj.j0(10, j) + ")"  // u64 十进制
```

**zq9.a(qo5, cee, j, xgb) op 工厂的第 4 参**——
op 创建时的 realtime 时钟戳（无符号 64 位）。

## 3. `x09` = 文档模型接口

`interface x09`——218 个文件引用，为文档/笔记模型
侧接口（`z5c.y(qo5,x09)` 内容高度助手所消费），
非线型协议类型。

## 4. 结论

- 校验契约架构闭环：ka4.a() → ybg.c → ValidationException。
- Realtime 时标 = u64 值类（op 工厂参数）。

## 5. Harmony 对齐

- 校验契约 → Harmony 各 encode 前置 `assertValid`
  等价物（fail-closed 一致）。
- Realtime → Harmony `bigint`/`number` u64 处理。

## 6. 验证

`d02-ka4-xgb.mjs` 静态断言。

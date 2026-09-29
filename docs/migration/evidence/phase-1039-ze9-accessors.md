# Phase 1039 证据 — ze9 访问器→字段映射 + led

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ze9` 访问器映射

| 访问器 | 返回字段 | 语义 |
|---|---|---|
| `c()→ttf` | `a` | **noteId**（主 id） |
| `a()→long` | `e` | **timestamp** |
| `b()→ttf` | `d` | 另一 ttf（editorUserId?
  folderId?） |
| `d()→led` | `new led(c)` | **schemaVersion 装箱**
  ——`led` 是 short value-class |
| `e()→ttf` | `f` | 又一 ttf |
| `f()` | （b 的访问器推断） | — |

## `led` = short value-class 装箱

```java
public final class led {
    public final short a;            // schemaVersion
    public /* synthetic */ led(short s);
    public static String a(short s);  // toString
}
```

- `ze9.c` (short) 经 `d()` 装成 `led`——**schemaVersion
  的值类包装**（类型安全 schemaVersion）。

## 字段布局

```
ze9 { a:ttf=noteId, b:ttf, c:short=schemaVersion→led,
      d:ttf, e:long=timestamp, f:ttf }
```

## HarmonyOS 决策

`ze9` 记录保留；`led` short-wrapper→ArkTS
类型包装（`type SchemaVersion = number` + 装箱）。

## 产出

- fixture `d02-ze9-accessors.mjs`（10 断言）。
- ADR-0983；中文报告。

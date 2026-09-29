# Phase 1053 证据 — FlatBuffers 写入路径（serializer 注册表）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `zwd` = struct serializer 注册表

```java
public static final pce a = new pce(new z0c(21));  // lazy map
public static final int a(xwd xwdVar, a aVar) {
    Map map = (Map) a.getValue();
    wx4 wx4Var = (wx4) map.get(npbVar.b(cls));   // KClass→serializer
    if (wx4Var != null) return invoke(xwd, builder).intValue();
    rgc.b(...); throw null;                      // 未知类型 fail-loud
}
```

## `z0c` case 21 = map 构建器

`mx7` LinkedHashMap 逐个 `put(npb.b(X.class), serializer)`；
内联 `ywd`/`yec` wx4 实现逐类型写出。

## builder API（`com.google.flatbuffers.a` = FlatBufferBuilder）

| 方法 | 语义 |
|---|---|
| `t(int size, int extra)` | prep/对齐 |
| `v(float)` / `w(int)` / `b(byte)` / `f(long)` | 写标量 |
| `j(int slot, int off)` | 表字段=偏移 |
| `k(ByteBuffer)`/`l(CharSequence)` | 建向量/字符串 |
| `r()` | 完成→offset |

`apb.Z(qed,a)` 示例：`t(4,8)` → `v(c)` `v(d)` → `r()`。
`yyd` 内联：`t(4,20)` 对两段 `t(4,8)` 浮点+`w(int)`→`r()`。

## 读/写对偶

读：`cee`/`xwd` 基类 + `c(slot)`/`e()` 访问器（Ph 1043）。
写：`zwd` 注册表 + `a` builder + `apb/zwd/rr2` 助手族。

## Harmony 决策

- 写入经统一 `zwd`-等价注册表分派；builder API 对应
  ArkTS FlatBufferBuilder 封装；未知类型 fail-loud 保留。

## 产出

- fixture `d02-fb-write-path.mjs`（11 断言）。
- ADR-0997；中文报告。

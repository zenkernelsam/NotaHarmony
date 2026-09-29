# Phase 1041 证据 — xag hex 助手 + cxc pageId + ee8 op

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `xag` = hex 格式化助手

```java
public abstract class xag {
    public static void c(long j, byte[] bArr,
                         int i, int i2, int i3) { ... }
}
```

- `ttf.toString` 的 UUID-hex 写器——把 long 的
  各字节按位写 hex 字符到 `bArr`。

## `cxc extends xwd implements ka4, exc`

```java
public final class cxc extends xwd implements ka4, exc {
    public final int C();        // 页序号?
    public final String a();     // ka4 验证
}
```

- **pageId** 类型——`z5c.Z(cxc)` 生成页 id
  （Phase 1006）；`exc` = 页相关 iface。

## `ee8 extends cee implements ka4`

- `cee` = op-payload 基类；`ee8` = **MODIFY_PDF_FIELD
  op**（Phase 964 定名）。

## ID/op 类型关系

- `ttf` = UUID 实体 id；
- `xwd` 系（utf/qo5/cxc）= FlatBuffer wire id；
- `ka4` = 验证 iface（全实现 `a()`）。

## HarmonyOS 决策

`xag`→hex format helper；`cxc` pageId→同构；
`ee8` op→MODIFY_PDF_FIELD。

## 产出

- fixture `d02-helpers.mjs`（10 断言）。
- ADR-0985；中文报告。

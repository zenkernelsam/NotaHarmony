# Phase 1040 证据 — ID 类型分类（ttf/utf/qo5/rh8/xwd）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ttf` = UUID {msb,lsb}

```java
public final class ttf implements Comparable, Serializable {
    public static final ttf K = new ttf(0, 0);
    public final long I;   // msb
    public final long J;   // lsb
    public final String toString() {
        // xag.c hex → 8-4-4-4-12 canonical
    }
}
```

- **noteId/folderId/entity-id 类型**——两个 long
  承载 UUID；`K`=零 UUID 哨兵。

## `xwd` = FlatBuffers struct/table 基类

```java
public abstract class xwd {
    public int I;            // 偏移
    public ByteBuffer J;     // 底层 buffer
    public final void b(int i, ByteBuffer bb);
}
```

## `utf`/`qo5` extends xwd = wire 结构 id

- `utf`：`a()→String`,`c()/d()→long`——另一个
  FlatBuffer id 视图（note/element id 的 wire 态）。
- `qo5`：`a()→String`,`c()→short`,`d()→int` =
  **OpId{site:short, logicalTime:int}**——
  因果时序 op 标识（Phase 993 的 `(ts<<32)|site`
  pack 对应）。

## `rh8` = 空 iface stub

- 反编译空文件（占位 iface）。

## `ka4` = 验证 iface（Phase 977）

- `utf`/`qo5 implements ka4`——`{a()→String}` 验证
  访问器。

## HarmonyOS 决策

- `ttf`→ArkTS `{msb:number, lsb:number}` 或
  `string UUID`——canonical toString 保留；
- `qo5` OpId{site,logicalTime}→同构 struct；
- `xwd` FlatBuffer-struct 基类→BufferView 等价。

## 产出

- fixture `d02-id-types.mjs`（10 断言）。
- ADR-0984；中文报告。

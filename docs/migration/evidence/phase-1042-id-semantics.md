# Phase 1042 证据 — ttf/utf/cxc 完整语义

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ttf` = UUID 完整语义

```java
public final class ttf implements Comparable, Serializable {
    public final long I;   // msb
    public final long J;   // lsb
    public final byte[] a();          // 16B 序列化
    public final int compareTo(obj);
    public final boolean equals(obj);
    public final int hashCode() {     // I^J
        return Long.hashCode(I ^ J);
    }
}
```

- `a()` = 16 字节序列化；hashCode=`I^J`。
- `K` = 零 UUID 哨兵。

## `utf extends xwd` = wire UUID

```java
public final class utf extends xwd implements ka4 {
    public final String a();   // ka4
    public final long c();     // msb?
    public final long d();     // lsb?
}
```

- 两个 long 访问器——wire 态 UUID（同 ttf 两-long）。

## `cxc.C()` = 页序号

```java
public final int C() {
    return this.J.getInt(this.I + 8);   // offset+8 int
}
```

- `cxc` pageId 的 `C()` = 结构体 offset+8 的 int =
  **页序号**（页 id 内含页序）。

## ID 关系

| 类 | 载体 | 语义 |
|---|---|---|
| `ttf` | {long,long} | UUID（note/folder/entity） |
| `utf` | xwd wire | wire-UUID（a()+c()+d()） |
| `qo5` | xwd wire | OpId{site,logicalTime} |
| `cxc` | xwd wire | pageId（C()=页序@+8） |

## HarmonyOS 决策

ttf UUID 全语义保留；cxc.C() offset-8 页序读
保留（wire 布局一致）。

## 产出

- fixture `d02-id-semantics.mjs`（10 断言）。
- ADR-0986；中文报告。

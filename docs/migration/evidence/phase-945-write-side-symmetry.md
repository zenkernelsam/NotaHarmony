# Phase 945 证据 — 写端↔读端对称首证：`haj.c` + `nti.X`

## `haj.c(ln2, builder)` = CreatePage 写器（实证）

```java
C(4)                              // 4 字段表
j(0, nti.X(cxc))                  // f0: position = 12B inline
h(1, vv7.L(nz9))                  // f1: background nz9 偏移
e(2, pageCount, 1)                // f2: pageCount 默认 1
c(3, oz9.I, 0)                    // f3: bookmarked 默认 0
n()                               // endTable
```

**写端 f0-f3 ↔ 读端 c(4)/c(6)/c(8)/c(10)**（908）——
`4+2i` 公式两侧闭环。

## `nti.X(cxc, builder)` = SeqId 12B 内联写器（实证）

```java
t(4, 12)          // 4 元素 12 字节结构
w(index)          // writeInt → 字节 8-11（逆序前推）
w(timestamp)      // writeInt → 字节 4-7
s(2)              // pad 2 → 字节 2-3
y(site)           // writeShort → 字节 0-1
r()
```

FlatBuffers 结构逆序写 → 线型 `{site:u16@0,
pad:u16@2, timestamp:u32@4, index:u32@8}`——
**与 880 读端布局逐字节一致**。

## 方法映射

| builder 方法 | 语义 |
|---|---|
| `C(n)` | startTable n 槽 |
| `j(slot,off)` | 字段写入 inline 偏移 |
| `h(slot,off)` | 字段写入表偏移 |
| `e(slot,v,def)` | int 带默认 |
| `c(slot,v,def)` | byte 带默认 |
| `t(elems,bytes)` | startStruct |
| `w/y/s` | int/short/pad |
| `n()/r()` | endTable/endStruct |

## 结论

首对写↔读对称完整证明：ln2 f0-f3 序 +
cxc 12B 布局两侧逐字节闭环。

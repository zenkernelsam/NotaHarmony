# Phase 975 — 值类包装与 `jmf`/`ix4` 接口

来源：`decompiled_1.0.3/sources/defpackage/{jmf,mmf,tmf,cmf,ix4,xx4,nl8,hd,xd8}.java`

## 1. 值类包装（inline value classes）

| 类 | 字段 | 语义 | 出现处 |
|----|------|------|--------|
| `mmf` | `int I` | UInt32/int 包装 | fileSize、unicodeScalar |
| `tmf` | `long I` | **long 包装 = ZIndex** | ie8 f5、yn2/ke8 zIndex |
| `cmf` | `byte I` | UByte 包装 | a3d SetUInt8 |

均 `implements Comparable`——线型承载原语位宽。

## 2. `jmf` = ByteList 接口

```java
public interface jmf {
    int a();          // size
    byte h(int i);    // byteAt
    hmf iterator();   // 字节迭代器
}
```

实现：`nl8`（可变 ×1.5 增长）、`hd`/`xd8`
（均兼 `w71` 标记 = 冻结/不可变变体）。

**关键联结**：`ys2.O` 签名中 3×`jmf` =
dm2 CreateInk 的三条编码路径字节向量
（encodedCenterPath/CustomPath/FillPath）——
Phase 927"原始字节向量"写侧实证闭环。

## 3. `ix4` = 元素提供器接口

```java
public interface ix4 extends xx4 {
    Object invoke(Object obj);   // Function1
}
```

`q5(N,holder,table)`/`wj9(N,holder,table)`/`o1`/`d1.W`
均实现 ix4——向量写器的逐元素懒物化抽象
（Phase 925/933 读侧对应）。

## 4. Harmony 对齐

- mmf/tmf/cmf → Harmony 直接 u32/i64/u8 字段。
- jmf ByteList → Harmony `Uint8Array`/`number[]`。
- ix4 提供器 → 无对应物（写器内部实现细节）。

## 5. 验证

`d02-value-wrappers.mjs` 静态断言。

# Phase 987 — `zae` 统一视图层（uae/yae/tae/xae/lv2.U·V）

来源：`decompiled_1.0.3/sources/defpackage/{zae,uae,yae,tae,xae,lv2}.java`

## 1. `zae` 接口 = 三种 root 的统一视图

```java
x63 a();        // 格式枚举
short b();      // schemaVersion
ByteBuffer c(); // ★原始 backing buffer（cee.J）
Iterator d();   // 零拷贝 op 迭代器
List e();       // 物化 op 列表
```

## 2. 实现分派

| impl | root | x63 | b()= | d() | e() |
|------|------|-----|------|-----|-----|
| `uae`(a=0) | r29 NoteBundle | I | r29.q() | tae | lv2.T |
| `yae` | vt9 OpsBundle | J | vt9.k() | xae | lv2.U |
| `uae`(a=1) | zgb ReceiveOpsEvent | K | zgb.l() | tae(byte) | lv2.V |

## 3. `c()` = **源 ByteBuffer 直返**

```java
case 0: return ((r29) d).J;   // mmap 原 buffer
case 1: return ((zgb) d).J;
```

**defer 写路径因此字节直通**——`nce.g` defer 分支把
`zae.c()` 原样写盘，零反序列化/重编码开销，
保证 blob byte-exact。

## 4. `tae`/`xae` = 共享 holder 迭代器

```java
tae: K=uq9 holder, L=index, J=count
next(): r29.r(K, L++) / zgb.m(K, L++)   // ★同一 holder 复用
remove(): UnsupportedOperationException("read-only")
```

⚠️ **next() 返回同一 uq9 实例**（重 init）——调用方
不得跨 next 保留引用；需要持久集合走 `e()` 物化。

`xae` = vt9 变体（同构）。

## 5. `lv2.U`/`V` = vt9/zgb 物化器

与 `T(r29)` 同构：`count<=0 → hw3.I`；`m18.S()` builder；
逐 `uq9` `l(uq9,i)`/`m(uq9,i)`；`m18.E` 冻结。
`lv2.W(s83)` = DeleteEntities 墓碑向量物化（`p(i,cxc)`）。

## 6. Harmony 对齐

等价：视图层抽象三 root + 源 buffer 直通 +
共享-holder 迭代（Harmony 侧可保留同语义或
物化为不可变列表）。

## 7. 验证

`d02-zae-view-layer.mjs` 静态断言。

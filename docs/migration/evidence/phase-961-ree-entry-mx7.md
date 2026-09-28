# Phase 961 — `ree` 序列化总入口 + `mx7`/`pce`/`rgc` 配套

来源：`decompiled_1.0.3/sources/defpackage/`{ree,mx7,pce,rgc}.java

## 1. `ree` — 表序列化顶层入口

```java
pce a = new pce(new z0c(24));   // z0c 注册表的 SynchronizedLazy

int a(cee, a):
  wx4 ser = ((IdentityHashMap) a.getValue()).get(cee.getClass());
  ser != null → ser.invoke(cee, a)  // 返回 int 偏移
  else → rgc.b(mpb.a.b(cee.getClass()).toString()) → throw

byte[] b(cee):
  c8d → dk4.a → p(a(cee,builder)) → A() → rh8.q
```

**完整写路径**：`ree.b(任意cee表)` → 惰性 z0c →
IdentityHashMap 按运行时类精确匹配 → 逐型 wx4 写器 →
builder.finish → 字节数组。

## 2. `rgc.b(str)` — **fail-loud** 未注册类型护栏

```java
throw new IllegalStateException(
  "Unknown type '" + str + "', will lead to data loss "
  + "when written to disk. Likely programmer error.");
```

未注册类序列化时**直接 ISE**——原版对未知类型零容忍
（防静默丢数据）。`mpb.a.b(cls)` = KClass 限定名。

## 3. `pce` = Kotlin **`SynchronizedLazyImpl`**

```java
volatile J = t3i.c0(UNINITIALIZED); K = 锁对象
getValue: 双检锁；首次 invoke 后 I=null（释放λ）
a() = isInitialized
```

z0c 80 项注册表首次使用时才构建。

## 4. `mx7` = Kotlin **`MapBuilder`**（`buildMap` 底座）

`Object[]` 键 + `Object[]` 值 + `int[]` 哈希桶 + `int[]` 链
（`iHighestOneBit(i*3)` 桶长），`V` = 密封空单例，
`lk6` = MapBuilder 标记接口。**z0c 结构注册表用 mx7**
（kotlin map），表注册表用 `IdentityHashMap`（引用相等）——
两注册表容器语义有别：结构按 equals、表按 identity。

## 5. Harmony 对齐

- `ree.b` → Harmony 等价总入口（class→writer 表查找 +
  fail-loud）。**未注册类型必须 throw 而非静默**——
  与原版 `rgc.b` 语义对齐（fail-closed）。
- IdentityHashMap 语义 = ArkTS `Map` 用类引用作键等价。
- pce 惰性 = ArkTS 顶层 const + 首访初始化即可。

## 6. 验证

- `d02-ree-entry-mx7.mjs` 静态断言。

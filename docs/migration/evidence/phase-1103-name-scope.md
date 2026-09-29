# Phase 1103 证据 — ym8 Name + xt4/wt4 作用域树 + 标记接口

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ym8 implements Comparable` = Kotlin `Name` 值类

```java
static ym8 e(String s);           // identifier
static ym8 g(String s);           // "<…>" 特殊名
static ym8 d(String s);           // 自动分派（<开头→g，否则 e）
static boolean f(String s);       // isValidIdentifier
asString() / asStringStripSpecialMarkers()
```

- `xt4.e = ym8.g("<root>")` —— 根作用域名。

## `xt4` / `wt4` = FqName 作用域解析树

```java
xt4 { String a; transient wt4 b; transient xt4 c; transient ym8 d;
      static { Pattern.compile("\\.") }       // 点分隔名
  wt4 a(ym8) → 子作用域;  wt4 b() → 父作用域 }
wt4 { xt4 a; transient wt4 b;  c = new wt4("") 空哨兵 }
```

点分隔限定名 → 作用域节点链（Kotlin 编译器/序列化 vendored 的
package-scope 解析）。

## 标记接口

- `uz` = 空 marker；`rr6` = `{K(Object)}` sink；`hli` = iface；
  `vz`/`uia` 挂这些 mega-merge 标记。

## Harmony 决策

- Name/作用域树仅用于序列化内部名解析 —— Harmony 无对应需求，
  fail-closed 直移 Name 语义（identifier vs `<special>`）备用。

## 产出

- fixture `d02-name-scope.mjs`（10 断言）。
- ADR-1047；中文报告。

# Phase 1114 证据 — lgf HAMT 节点 + f16 可变性令牌 + 集合基类

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `lgf` = 持久 hashmap 的 HAMT/TrieNode

```java
lgf { int a;         // 位图（32路 HAMT 的占用位）
      Object[] b;    // 子节点/条目槽
      f16 token }    // 可变性令牌
static lgf d = new lgf(0, new Object[0], null);   // 空节点
static lgf f(i, obj, i2, obj2, i3, f16)            // 两级 assoc
```

`lgf.f` = TrieNode.mutablePut —— 带 f16 令牌的同层 assoc；
`f16` = `MutabilityOwnership` 令牌（builder 期内允许原位改）。

## `f16` = mega-merge 令牌

`implements s24,co9,…` + `new f16(17..20)` int 判别变体 —
在 lgf 场景为 TrieNode 所有权令牌。

## 集合基类

- `m2 implements Collection,ik6` = 只读基（`add` 抛）。
- `n5 extends m2 implements Set` = 持久 Set 基。
- `y3 extends m2 implements List` = 持久 List 基。
- `zr5 extends List,Collection,ik6` = 持久 List 标记。
- `hw3` = `List,Serializable,RandomAccess,ik6` 空列表单例 `I`。

## 链路

`hja`(持久map) → `lgf`(HAMT 节点) + `f16`(令牌) →
`gja`(builder) → `m2/y3/n5` 只读集合基 —— kotlinx
immutable-collections 全栈 vendored。

## Harmony 决策

- 持久 map/list = HAMT trie + 所有权令牌 + 只读基类；
  Harmony 用结构共享 Map 拷贝或手写 trie 复刻。

## 产出

- fixture `d02-hamt.mjs`（10 断言）。
- ADR-1058；中文报告。

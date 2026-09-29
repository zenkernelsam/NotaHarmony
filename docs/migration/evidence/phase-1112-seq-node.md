# Phase 1112 证据 — f8d 序列节点 + g8d 长键 map + bxc spec

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `f8d` = 序列树节点

```java
f8d { short a; int b; long c;      // site/seq/位序
      qwc d;                        // 树导航（Phase 1092）
      List e; int f }               // 子元素 + 计数
  void a(hr5, int);                 // 锚点访问/派生
```

## `g8d implements Map,ik6` = 抽象 long→f8d map

`a(long)→f8d`、`b()→int`、`c()→Collection` —— `y51` 把它
适配到 `wia.c`（igf long-map）。

## `bxc implements jxc,bf0` = 文本序列 spec

```java
static sia v;                       // 共享/空索引
k5c b; sia c;                       // 空间索引
z4 d; kia e; cl2 f;
hja g; hja h;                       // 双持久 map（→iwc 双 gja）
```

## 链路

`bxc`(spec, 双 hja + sia) → `iwc`(live, 双 gja builder + wia) →
`y51`/`g8d` 适配 → `f8d` 节点 → `hr5` 锚 —— 完整文本序列
内部栈。

## Harmony 决策

- 序列树节点 = `{site,seq,pos, nav, children}`。
- spec 双持久 map ↔ live 双 builder；sia 空间索引承载 long 键。

## 产出

- fixture `d02-seq-node.mjs`（10 断言）。
- ADR-1056；中文报告。

# Phase 990 — `lgf` 持久化 op 树 + `mia` DFS 迭代器 + 导出排序键

来源：`decompiled_1.0.3/sources/defpackage/{lgf,mia,rgf,k79,ldj}.java`

## 1. `lgf` = 持久化 op 集合（树节点）

```java
public static final lgf d = new lgf(0, new Object[0], null); // EMPTY 单例
int a;            // 子树 size
Object[] b;       // 子节点/叶元素数组
f16 c;            // 尾缓冲?
static lgf f(int,obj,int,obj,int,f16)   // 节点工厂
int a()           // 递归 size（obj instanceof lgf 累加）
b(i,i2,obj)/c(lgf,i)/d(lgf)             // 不可变更新/拼接
```

→ 文档模型的 **immutable op-vector 树**（RRB/持久向量
风格，`Object[]` 中可嵌套 lgf）。

## 2. `mia` = DFS 迭代器

```java
I = ArrayList<rgf> 帧栈; J = 深度; K = hasMore
rgf{a=node[], b=idx}                 // 帧
a() = 下潜/回退补帧；耗尽 → K=false
```

`yk9` 导出路径经 `mia` 遍历全部 op。

## 3. `k79(3)/(4)` = 导出排序键（uq9.l()=op id）

```java
case 3: new mmf(uq9.l().d())   // ★qo5.timestamp → 主键
case 4: new ymf(uq9.l().c())   // ★qo5.site      → 次键
```

**导出排序 = (timestamp, site) 升序**——确定性规范序，
保证导出字节稳定。

## 4. `ldj.G1` = `d02` 链式比较器

`G1(ix4...)` → `new d02(ix4VarArr)`：按序取 key 逐对
比较（非 0 即返回）——`au1.K1` 用它排序 op 列表。

## 5. 语义链

导出：`mia` DFS 遍历 lgf 树 → fsi.P 过滤 →
`K1` 按 (ts,site) 排序 → q4j.c 写包。

## 6. Harmony 对齐

等价语义：不可变 op 集合 + DFS 遍历 +
(timestamp,site) 规范序；Harmony 可用不可变数组
等价物（无需持久树性能特征时退化为 ArrayList 快照）。

## 7. 验证

`d02-op-tree.mjs` 静态断言。

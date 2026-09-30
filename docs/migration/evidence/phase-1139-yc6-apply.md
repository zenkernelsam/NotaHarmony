# Phase 1139 证据 — yc6.z 空间索引应用 + yc6.G 提交

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `yc6.z(e0a plan, bool full, al2 tomb, List entities)`

```java
wia wia = this.L;                    // 实体存贮
k11 bounds = new k11();              // 划界 scratch
if (full) for (qo5 op : plan.b) {    // 每计划 op
  long key = (op.c()&0xFFFF) | ((op.d()&0xFFFFFFFF)<<32);
                                     // 打包 site16低|time32高
  wia.d = null;                       // cache 失效
  igf n = wia.c.n(key, 0, wia);       // 空间索引查
  if (n==null) n = igf.g;
  if (n != wia.c) { wia.c = n; wia.a = null; }
  vnd v = wia.d;
  if (v!=null) { v.a(bounds);          // 实体界
    for (x : ba6.P(bounds, entities)) { … }  // 每实体
  }
}
```

- 打包键 = **`(site&0xFFFF) | (time&0xFFFFFFFF)<<32`**
  （site 低 16 / logical-time 高 32）——与 `vnd`/`und`/`igf`
  空间栈的 `long` 键一致。
- `wia.c` = `igf` 长键开放寻址图；`wia.d` = memo 节点。
- `v.a(k11)` = `vnd` 产实体界；`ba6.P(bounds,list)` = 界内
  实体遍历。

## `yc6.G(List, al2, List, ff2)` = label2 挂起提交

调和第二挂起点 —— 应用后提交/广播（`ff2` 续体）。

## 语义

note 级 apply = 对合并计划逐 op：打包 opId→long → 空间
索引查实体节点 → 产界 → 界内实体逐一处理（z 路径是全
量 `if(z)`；非全量走其它分支）。

## Harmony 决策

- apply = 打包 opId(long)→空间索引→界→实体迭代；
  `wia` 存贮 + `igf` long-map + `vnd` 节点 + `k11` 界。
- Harmony：相同打包键 + 索引查 + 界迭代。

## 产出

- fixture `d02-yc6-apply.mjs`（10 断言）。
- ADR-1083；中文报告。

# Phase 1081 证据 — igf long-map 空间索引 + vnd 节点 + und 键

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 索引栈

```
ue4.J → sia{igf a, int b(代)}
         igf = {long a,b; long[] c 键; er6 d; Object[] e 值}
                = long→Object 开放寻址 map（packed opId→vnd）
vnd implements Comparable = {ly3 I 实体快照,
                             float J,K,L,M 包围盒4元,
                             boolean N, und O}
und{qo5 a, long b} = 打包键包装
```

- `sia.c` = 空索引单例 `(igf.g, 0)`；`int b` = 代次戳。
- `vnd` Comparable → 按包围盒/键排序（空间序）。
- 键 = `lt<<32|site`（Phase 1078）。

## Harmony 决策

- 空间索引 = long→节点开放 map；节点持实体快照+包围盒；
  `sia` 加代次戳支持失效。

## 产出

- fixture `d02-spatial-index.mjs`（10 断言）。
- ADR-1025；中文报告。

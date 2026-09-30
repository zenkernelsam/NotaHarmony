# ADR-1083：yc6.z 空间索引应用

## 状态

已接受（Phase 1139）。

## 决策

- `yc6.z` = 对合并计划逐 op：打包 `(site16|time32<<32)`
  →`igf.n` 空间索引→`vnd`→`k11` 界→`ba6.P` 实体迭代；
  `wia.d` cache 失效。
- `yc6.G` = label2 挂起提交。

## 依据

打包键 `&0xFFFF | <<32` + `wia.c.n` + `vndVar.a(k11)` +
`ba6.P`。

## 后果

Harmony：opId 打包 long 键 + 空间索引查 + 界迭代；
`igf` long-map + `vnd` 节点栈复刻。

# ADR-1067：物化快照/视图集合谱系

## 状态

已接受（Phase 1123）。

## 决策

- `f1a` = 页快照 `{int,rvb,cl2,kia}`；`rvb` = 文本块快照
  `{bxc,cl2×2,xgb}`。
- map：`kja`/`nja`=`ija` 惰性变换；`mja`/`oja`=`jja` 只读+fork。
- list：`ria`=`{bka,ArrayList}`；`q07` 只读；`lia`/`bka` 视图。

## 依据

物化链 spec+map+时戳快照 + 惰性/只读/builder 三模式。

## 后果

Harmony 快照 = spec+map+ts；集合视图三模式直移。

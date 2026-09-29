# ADR-1052：序列辅助 + 解码 + rowid

## 状态

已接受（Phase 1108）。

## 决策

- `njj.L` = `jxc` union 锚成员判定（map-TRUE / set-contains）。
- `njj.M` = 恒等矩阵判定（短路变换）。
- `xj2.f` = tombstone `bl2` 值解包；`xj2.g` = float 对解码
  （rh8.a 互逆）。`njj.z` = `last_insert_rowid()`。

## 依据

union 双模式 + bl2 包装 + bit-packed float + Room rowid。

## 后果

Harmony 对齐：union 判定、bl2 解包、float-pack 配对；
rowid → RDB API。

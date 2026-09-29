# ADR-1053：锚点集合 union + tombstone + 活锚 store

## 状态

已接受（Phase 1109）。

## 决策

- `jxc` = 锚集合 union（Set|Map 双模式）。
- `bl2` = tombstone 条目 `{qo5,key,value}`，`xj2.f` 解 `.c`。
- `iwc` = e4c 活锚 store = `wia` + `gja` + pending map。

## 依据

文本序列锚索引 = 空间 store + 因果 builder + pending。

## 后果

Harmony 文本锚存取 = union 判定 + tombstone 条目 +
空间索引/因果 builder 组合。

# ADR-1054：文本序列 spec→live + 长键适配

## 状态

已接受（Phase 1110）。

## 决策

- `iwc(bxc)` = 文本序列 spec→live（同 `qy0(ry0)`/`m5d(n5d)`
  对称）：`wia` store + 双 `gja` builder + `al2` tombstone +
  `xgb` 时戳 + 4×`hr5` 锚。
- `y51 extends g8d` = `wia` long-map → `f8d` 查找适配。
- `bxc implements jxc,bf0` = spec 自带锚集合 + spec 标记。

## 依据

spec→live 三度重复 = 原版固定架构模式。

## 后果

Harmony 文本序列 = spec/live 分层；锚 store 适配器 +
双因果 builder + tombstone + 锚。

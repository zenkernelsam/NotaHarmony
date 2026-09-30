# ADR-1075：锚点插入算法 + 文本 API

## 状态

已接受（Phase 1131）。

## 决策

- `e4c.g` = 插入：`njj.t` 树遍定位 → `s3c` 分裂
  （`n4c.a` 码点→idx + subSequence）→ tombstone 跳
  （`njj.L` + `zm7` 找未删）→ 新段 → `d4c`。
- API：`o/w/y` 锚位互转、`getText→jxc`、`d→nr5`。
- `knb`/`mnb` = out-param holder。

## 依据

树遍 + span 分裂 + tombstone 跳过链路。

## 后果

Harmony 文本插入 = 同构算法；out-param 用对象引用字段。

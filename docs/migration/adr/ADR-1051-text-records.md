# ADR-1051：文本应用记录 + 定位元素

## 状态

已接受（Phase 1107）。

## 决策

- `i4c` = 应用结果接口；`h4c` = `{ywc, qo5}` 记录。
- `uwc extends ywc` = 定位文本元素
  `{qo5, exc锚, long×2 时戳, Integer 位序}`。
- `xj2.f` = tombstone 存在判定。

## 依据

e4c.b case7 构造 uwc 记录链。

## 后果

Harmony 文本应用产出 `{element, opId}` 记录；定位元素含
锚点+时戳+位序；tombstone 先行过滤。

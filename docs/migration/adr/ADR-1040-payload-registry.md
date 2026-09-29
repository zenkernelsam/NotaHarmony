# ADR-1040：载荷类↔op 类型双向注册表

## 状态

已接受（Phase 1096）。

## 决策

- `zq9.a` = `Map<KClass,haa>` 31 条目（class→type，
  序列化端）；`z5c.x` = ordinal→class（反序列化端）。
- `npb`/`mpb` = KClass 工厂；`mx7` = 双数组紧凑 map。

## 依据

31 注册 + `npb.b(X.class)→oj6` + `mx7` 数组结构。

## 后果

Harmony payload 双向注册：序列化按类查 type，
反序列化按 type 构类。

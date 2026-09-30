# ADR-1068：ija 惰性物化 map

## 状态

已接受（Phase 1124）。

## 决策

- `ija` = 惰性物化因果 map：`d` 写穿 `I.put` + `J.remove` 失效；
  `get` 读 `J` memo → `I.get` → `e()` 变换 → 缓存；
  `a()` flush → `f(I.build())` 快照。
- `b/e/f` 抽象 = 子类值变换 + 快照工厂；`c()` 失效钩子。

## 依据

写穿 + 懒读缓存 + 冻结物化三合一；kja/nja 特化。

## 后果

Harmony：pending-map 写穿 + 懒读 memo + 快照工厂复刻；
派生缓存用 hook 失效。

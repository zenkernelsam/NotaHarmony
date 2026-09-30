# Phase 1129 证据 — al2 LWW tombstone map

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `al2 implements Map,ik6` = tombstone map（LWW 守卫）

```java
al2(cl2 spec) → gja I = spec.I.builder()    // builder over spec
a() → cl2 = new cl2(I.build())              // 冻结回快照

b(bl2 entry):                               // 加 tombstone
  existing = I.get(entry.b)                 // 按键查
  if (existing.a==null || so5.a(existing.a, entry.a) <= 0)
    I.put(entry.b, entry)                   // 仅保留更新 opId

c(ArrayList) → forEach b()                  // 批量
```

- tombstone = `bl2{qo5 删除opId, 键, 值}`（Phase 1109）。
- **删除也走 LWW**：仅当新 tombstone 的 opId 不旧于现有
  （`so5.a` 不增序）才写入 —— 早 tombstone 不可覆盖晚 op，
  保证因果收敛。
- `al2(cl2)`/`a()→cl2` = builder↔snapshot 循环（与 gja/hja 同型）。

## 与 `xj2.f` 配对

读侧 `xj2.f(obj, map)` = `map.get` + `bl2` 解 `.c`（值）。

## Harmony 决策

- tombstone = LWW 写入（opId 比较守卫），非单纯 set。
- Harmony 保留 `so5.a` opId 序守卫收敛。

## 产出

- fixture `d02-tombstone-map.mjs`（10 断言）。
- ADR-1073；中文报告。

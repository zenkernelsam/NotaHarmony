# Phase 1118 证据 — core/ 命名包泄漏：根页 id 哨兵 + SharedMemoryByteArena

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（`com/gingerlabs/notability/core/` 未混淆包）

## `core/model/a` = note 聚合 + 根页 id 哨兵

```java
static cxc k = nti.g(rh8.b(0, -1), 0);
// 根页 id = opId{site=0, timestamp=-1} → pageId seq=0
a { bs1 a; long b; fqa c; String d;
    ArrayList e; LinkedHashMap f; LinkedHashMap g }
```

**根页 = opId{0,-1} → seq 0** —— 文档首页的固定合成 id。

## `core/model/b` = ops→持久列表物化器

`a(a79)→th7`：`m18.S()` builder 遍历 `a79.H`（bja 快照）
折叠成 `th7` 持久列表 —— 文档 ops 的物化出口。

## `core/common/memory/SharedMemoryByteArena` = `c8d` 真名

- `ArenaClosedException extends IllegalStateException`（@Metadata
  Kotlin 注解完整保留）—— arena 关闭后访问抛此。
- 证实 Phase-1100：`c8d` = ashmem 字节 arena。

## `core/` 包图（未混淆）

`analytics / common(memory) / flatbuffers / glmath / model /
network / retrofit / user` —— 真实分层名。

## `core/flatbuffers/ValidationException` 命名类

`ybg.c` 抛的即此（Phase-1098 校验异常）。

## Harmony 决策

- 根页 id = `opId{0,-1}+seq0` 合成（Harmony 同构）。
- ops 物化 = 遍历 bja 快照 → 持久列表。
- arena 关闭后访问 → Harmony 抛 IllegalStateError 等价。

## 产出

- fixture `d02-named-core.mjs`（10 断言）。
- ADR-1062；中文报告。

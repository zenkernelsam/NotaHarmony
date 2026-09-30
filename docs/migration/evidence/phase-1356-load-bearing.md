# Phase 1356 证据 — 承重基线引用验证（正确）

验证 CRDT 互操作结论所依赖的承重基线引用（区别于
算法层的误标）—— **均正确**。

## `exc` = CRDT 比较器接口（✅ 正确）

```
exc.java:
  default int A0(exc excVar) —— 默认比较方法存在
  // 配合 exc.A0 语义：signed-timestamp 优先 +
  //   unsigned-site 次序（Harmony OperationIdentity 复刻）
```

→ `exc.A0` 比较器引用**正确** —— CRDT 排序互操作结论
的承重证据成立。

## `haa` = 30-op 分类枚举（✅ 正确）

```
haa.java = op 枚举：
  SET_METADATA(1) CREATE_PAGE(3) CREATE_RECORDING(5)
  INSERT_CHAR(7) INSERT_STRING(8) REMOVE_CHAR(9)
  REMOVE_CHARS(10) REVIVE_CHARS(11) CREATE_INK(15) …
```

→ `haa` op 分类引用**正确** —— Harmony `ORIGINAL_*`
op 映射的字节值逐字节对照原版。

## 对比：算法层误标

区别于 Phases 1352–1355 更正的算法基线误标（`b90`/
`w4a`/`wy5`/`hr4`/`sqh`），承重的线格式引用（`exc`/
`haa`/`cee`/`uq9`/`tmf`）经实读验证正确 —— CRDT 互
操作结论**不受影响**。

## Harmony 决策

承重引用（`exc.A0`/`haa` op-enum）验证正确；算法层
引用已更正 —— 线格式互操作结论稳固。

## 产出

- fixture `d02-load-bearing.mjs`（10 断言）。
- ADR-1297；中文报告。

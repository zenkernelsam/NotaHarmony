# Phase 1008 证据 — 查询构造器（e6c + mlc 模式 + m2a 变换）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `mlc` = SearchMode（5 值）

```
SUBSTRING(0) WHOLE_WORD(1) EXACT(2) PREFIX(3)
TOKEN_PREFIX(4)
```

## `e6c` 查询构造器（abstract，两静态）

### `e6c.a(str)` — LIKE 模式（SUBSTRING 路径）

```
folded = nnc.a(str)             // 折叠
blank → null
escape: "\\"→"\\\\"  "%"→"\\%"  "_"→"\\_"
return "%" + escaped + "%"      // ESCAPE '\' 配套
```

### `e6c.b(str, mlc)` — FTS MATCH 串

```
tokens = a.g(nnc.a(str))   // [^\p{L}\p{N}]+ 分词+去空
空 → null
ordinal:
  0 SUBSTRING   → null        // 走 LIKE 路径
  1 WHOLE_WORD  → join " "    // t1 t2（FTS 隐式 AND）
  2 EXACT       → "\"t1 t2\"" // 短语
  3/4 PREFIX/TOKEN_PREFIX
                → join " "，逐 token m2a(23) 变换
```

- 分词正则 `a = [^\p{L}\p{N}]+`（非字母数字切割，
  Unicode L/N 类 —— 中日韩全保留为单 token）。

### `m2a` case 23 = 前缀变换

```java
return str.concat("*");   // FTS5 token* 前缀匹配
```

→ PREFIX/TOKEN_PREFIX 均生成 `t1* t2*`。

## 完整查询语义表

| 模式 | 生成串 | SQL |
|------|--------|-----|
| SUBSTRING | `%folded%`（转义） | `foldedText LIKE ? ESCAPE '\'` |
| WHOLE_WORD | `t1 t2` | `search_fts MATCH ?` |
| EXACT | `"t1 t2"` | 同上 |
| PREFIX | `t1* t2*` | 同上 |
| TOKEN_PREFIX | `t1* t2*` | 同上 |

## HarmonyOS 决策

- LIKE 路径逐字保留（转义规则 + `%` 包裹）。
- FTS 模式串构造保留语义，但查询在 LIKE 引擎上
  等价实现：WHOLE_WORD/EXACT/PREFIX 均需
  应用层词边界判定（relationalStore 无 MATCH）——
  **记为待实现工作项**，折叠层已等价（ADR-0948）。

## 产出

- fixture `d02-query-builder.mjs`（14 断言）。
- ADR-0952；中文报告。

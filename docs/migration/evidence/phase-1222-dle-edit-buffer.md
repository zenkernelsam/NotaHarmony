# Phase 1222 证据 — dle = TextEditBuffer 方法面

来源：`defpackage/{dle,rnh,o7a}.java`。

## `dle implements Appendable` = TextEditBuffer

| 方法 | 真实语义 |
|---|---|
| `append()×3` | 追加文本/字符/子串 |
| `b(int,int,int)` | **setComposingRegion(start,end,sessionId)** — IME 组合标记 |
| `c(int,int,CharSequence)` | **replace(start,end,text)** — `rh8.v(v,0,len)` 双界钳位 + 文本界校验 |
| `d(int,int,List)` | markup/span 插入 |
| `e(jqe)` | **setComposition(TextRange)** |
| `f(long)` | **setSelection(packed)** |
| `a()→rnh` | **finishEditing** → 提交产出 `rnh` |
| `w()` | abort/放弃编辑 |
| `toString()` | `K` 缓冲文本 |

## `o7a` = 内部可变缓冲

`dle.K`/`o7a` = gap-buffer/可变 CharSequence —
`length()`/`charAt`/`subSequence` 编辑时索引。

## `rnh` = 编辑会话/commit 结果

`a()→rnh` 持有 `dle` 最终态（Phase 1191 `dle{ele,
f76,o7a,rnh}` 字段对齐 —— `rnh` 是会话元数据）。

## `c` 钳位细节

```java
int iV  = rh8.v(i,  0, o7aVar.length());   // start 钳界
int iV2 = rh8.v(i2, 0, o7aVar.length());   // end 钳界
int iV3 = rh8.v(0,  0, cs.length());       // textStart 钳界
int iV4 = rh8.v(len, 0, cs.length());      // textEnd 钳界
```

四重钳位 —— replace 参数全部边界安全化。

## Harmony 决策

`TextEditBuffer` → Harmony 编辑缓冲：`replace`/
`setComposingRegion`/`setSelection`/`finishEditing`
+ `Abort`；`rnh` 会话 → 提交记录；`o7a` 缓冲 →
`StringBuilder`/gap 实现。

## 产出

- fixture `d02-dle-edit-buffer.mjs`（10 断言）。
- ADR-1166；中文报告。

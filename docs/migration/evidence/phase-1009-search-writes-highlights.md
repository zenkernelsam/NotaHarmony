# Phase 1009 证据 — search_item 写入 DAO + 高亮模型 + rects 实情

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `sq1` = UPSERT 绑定 lambda

```java
sq1(String noteId, int type, String subId,
    String pageId, String foldedText, byte[] rects)
INSERT INTO search_item (...) VALUES (?,?,?,?,?,?)
ON CONFLICT(noteId,type,subId) DO UPDATE SET
  pageId=excluded.pageId, foldedText=excluded.foldedText,
  rects=excluded.rects
```

绑定：`h0(1,noteId)` `l(2,type)` `h0(3,subId)`
`pageId null→r(4)` `h0(5,foldedText)`
`rects null→r(6)` else `o(bArr,6)` —— **双可空列**。

## `klc` = 写入 DAO

- `b(ArrayList, ff2)`：逐元素 `l96.L0` 事务 + sq1。
- 实证：`new sq1(strB, iE, strD, strC, strA,
  (byte[]) null)` —— **rects 恒写 null**！
  该列在本版本中未由写路径填充（保留兼容位）。
- `ro3(str,int,str2,2)` = 删除 lambda（同一 file）。

## 高亮模型

- `alc` = `SearchHighlights{rects:List}` —— 查询侧
  结果（行内 rect 对象列表，非 byte[]）。
- `q1f` = `RichTextHighlightsCacheEntry{documentState,
  textOrigin:long(via zn9.c), query:String,
  rects:List}` —— 内存高亮缓存（键 = 文档态+查询）。

## `glc` 与 rects 列

- `glc` 是查询投影类：`toString` 的 `rects=` 恒输出
  `Arrays.toString(null)` —— glc 不物化 rects；
  列仅被 sq1 写入路径引用（当前恒 null）。

## HarmonyOS 决策

- UPSERT 平移 `relationalStore.insert` 冲突策略
  （ON CONFLICT REPLACE/UPDATE 语义等价）。
- `rects` 列保留为可空 BLOB（恒 null —— 与原版
  行为一致；勿删）。
- `alc`/`q1f` 内存高亮模型等价。

## 产出

- fixture `d02-search-writes.mjs`（12 断言）。
- ADR-0953；中文报告。

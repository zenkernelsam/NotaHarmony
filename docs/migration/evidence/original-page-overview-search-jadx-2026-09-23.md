# 原版页面管理面板页内搜索证据 — JADX 静态提取

日期：2026-09-23 · 来源：`decompiled_1.0.3`（Notability Android 1.0.3）· 仅静态证据。

## 1. 搜索入口（面板内行项）

`r22.java` case 24：`go5.b(ue4.A(uz4), tl7.U(uz4, R.string.feature_note__content_manager_search), …)`
—— 面板内一行「图标 + "Search"」入口，点击即激活搜索模式。
`content_manager_search` = **"Search"**（strings.xml）。

## 2. 状态字段（`qd2.java` UiState）

```
isSearchActive (g), searchQuery (h), searchMatchingPageKeys (i)
```

## 3. 激活与查询写入（`de2.java`）

- `de2.l()`：`qd2.a(value, null,…,true,…,447)` —— mask 447 只替换
  bit6（isSearchActive），即**进入搜索模式**（不改页/过滤/选择）。
- `de2.s(String)`：`xd9Var.d.k(null, str)` 把 query 推进独立查询流，
  同时 `qd2.a(…,str,…,383)` 把 query 写进 `searchQuery`（mask 383
  保留命中集字段 i）。
- `sl.java` case 9：查询流产出 `Set set2` → `qd2.a(…,set2,…)` 写回
  `searchMatchingPageKeys`。

## 4. 过滤管线（`qd2.c()`）

```java
if (!this.g || lvd.E0(this.h)) {
    return list;                     // 未激活 或 query 空白 → 原样返回
}
ArrayList out = new ArrayList();
for (Object obj : list) {            // list 已是 nd2 过滤结果
    if (this.i.contains(z5c.Z(((pd2) obj).a))) out.add(obj);
}
return out;
```

⇒ 语义：**先 nd2 过滤，再与命中页键集合求交**；`pd2.a` 为页身份
（`cxc`），`z5c.Z` 转键，`lvd.E0` 为 isBlank 判定。

## 5. Harmony 对齐点（Phase 646）

- 面板头部 🔍 开关对齐 `content_manager_search` 行 → `searchActive`；
  关闭时清 query/命中集。
- `TextInput` onChange → `runSearch()`：`searchGeneration` 防乱序；
  空白 query 立即清命中集（对齐 `lvd.E0` 分支）。
- `StrokePersistence.searchPageIdsWithText`：`search_item` 表
  `note_id + folded_text LIKE` → `DISTINCT page_id`（该表本就是
  全文索引的 page 级粒度，`folded_text` 已由 `foldSearchText`
  规范化）。
- `visibleItems()` 尾段求交；命中集未回时为空集 → fail-closed
  空列表（与原版 `qd2.i` 初始空集一致）。

## 6. 差异登记

- 原版 query 流经 `xd9.d` 独立流（疑似 debounce）；Harmony 每次
  onChange 直接发 SQL（结果集小、查询轻量），以 generation 计数
  丢弃迟到结果——行为等价，无 debounce 节流。

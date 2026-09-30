# Phase 1152 证据 — core/model 笔记+页线模

来源：`core/model/{a,b,c}.java`（命名包）。

## `core.model.a` = 笔记线模/bundle

```java
static cxc k = nti.g(rh8.b(0,-1), 0)   // 根页 sentinel
{ bs1 a;                              // bundle 头
  long b;                             // 时间/版本
  fqa c;                              // origin
  String d;                           // 名
  ArrayList e;                        // 页/实体表
  LinkedHashMap f..i;                 // 实体图×4
  qo5 j }                             // op id
a(fqa, String, int) ctor; bs1=l96.M(0)
```

笔记全量序列化表示 —— 根页 + origin + 名 + 4 实体图。

## `core.model.c` = 页/块线模

```java
{ ArrayList a(ops);                   // op 表
  bs1 b; cxc c(pageId);               // 页 id
  fqa d; LinkedHashMap e..g;          // 子图
  ArrayList h }
c(List ops, bs1, cxc pageId, fqa)
```

页 op 表 + page-id + 子实体图 —— 页级 wire-model。

## `core.model.b` = 抽象物化器

`a(a79)→th7` = live note→持久集物化。

## 语义

`core/model` = 序列化/线模层：
- `a` = 笔记 bundle（根页 sentinel + origin + 名 +
  实体图）；
- `c` = 页模型（op 表 + pageId + 子图）；
- `b` = live→快照物化。

与 `v69`/`a79`（live CRDT）对偶 —— 这是**线/盘**侧。

## Harmony 决策

- 笔记/页线模 = `{bs1头, origin, name, op[], entityMaps,
  pageId}` —— 存盘/同步的序列化载体。
- Harmony：同构 Record 线模 + sentinel 根页。

## 产出

- fixture `d02-wire-model.mjs`（10 断言）。
- ADR-1096；中文报告。

# Phase 884 证据 — `ye9`/`led`/`ttf` 标识层

## 目的

登记会话所需的 note 标识三元组（`decompiled_1.0.3`，
classes.dex 实名/值类）。

## `ttf` = UUID 值类

`ttf implements Comparable, Serializable`：`{I:long, J:long}`
= 128 位 UUID（`utf` 线结构的内存值类对——875 登记
utf=16B 线结构，ttf=模型侧）：

- `a()` = 16 字节大端序列（先 I 后 J 各 8B 高位先行）。
- `toString()` = 36 字符标准 UUID（`xag.c` 十六进制 +
  `-` 分隔：8-4-4-4-12）。
- `K = new ttf(0,0)` = NIL UUID。
- `compareTo`/`equals`/`hashCode` 全实现（有序键可用）。

## `led` = 编辑站值类

`{a:short}` siteId 包装；`toString()`=`a(short)` 格式化。
`tzc.O` = `ye9.d().a`——会话站点。

## `ye9` = note 会话上下文接口

`c()`→ttf（note UUID）、`d()`→led（已解析编辑站——
返回 null 时 tzc fail-closed）。`ye9` 另持 `M`/`N` 构造
所需聚合件（aa9/b40 各自拿 ya9/qy3+ttf）。

## 派生用法锚点

- `tzc` 构造：`ledVarD.a`→O、`ttf`→aa9/b40 键。
- `sxe`：`o69(ttf)` 包装入 k1a 命令目标。
- `ttf`/`utf` 双形态：网络面用 utf 线结构、模型面用
  ttf 值类（同一 UUID 两表示）。

## Harmony 侧

- `OriginalNoteBundlePageIdentity`：`readInlineBytes(0,16)`
  + `decodeOriginalUuid` = 16B 内联 UUID 解码（与 `ttf.a()`
  同字节序）；`originalNoteIdsMatch` 比较逻辑对应。
- siteId/`led` ↔ `OperationIdentity.siteId`（u16）；
  note UUID ↔ bundle.noteId 字符串。
- NIL UUID `K` ↔ Harmony uuid 全零校验。

## 结论

标识三元组实名：ttf=128b UUID 值类（utf 线对）、led=
siteId 包装、ye9=会话上下文。Harmony 16B UUID 解码逐字节
等价。纯文档+fixture 阶段。

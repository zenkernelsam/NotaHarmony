# Phase 915 证据 — 字符 op 四表（e46/f46/qub/f2c）

## 目的

文本字符 op 族实名（869 type7-14 注册的读侧补全）。

## 四表（toString 实证）

### `e46` = `InsertChar`
`{location:cxc@0(c4), textField:qo5@1(c6),
unicodeScalar:mmf@2(c8)}`
—— 单字符 = cxc 位置 + **UInt Unicode 标量**。

### `f46` = `InsertString`
`{location:cxc@0(c4), string:String@1(c6),
textField:qo5@2(c8)}`

### `qub` = `RemoveChars` / `f2c` = `ReviveChars`
同构：`{locations:cxc[]@0(c4), textField:qo5@1(c6)}`
—— `l(i,cxc)` 以 `(i*12)+f(v)` 寻址：
**cxc 12B 内联结构向量**（880 位置 ID 实证复用）。

## 注册（zq9）

`e46→INSERT_CHAR`、`f46→INSERT_STRING`、
`qub→REMOVE_CHARS`、`f2c→REVIVE_CHARS`。

## CRDT 文本模型

- 插入锚定 **cxc 位置 ID**（{siteId,timestamp,index}
  12B），非字符索引——并发插入位置稳定。
- 删除/复活同载体：cxc[] 向量 → **墓碑式 CRDT**，
  Revive 复用同一向量语义回标记。
- textField qo5 指向承载文本的实体。

## Harmony 核对

`Original*CharOperation`/`TextField` 编码对齐：
cxc 位置锚定 + mmf Unicode 标量 + cxc[] 删除集。

## 结论

文本 CRDT 证据闭合：位置 ID 锚定 + 墓碑删除/复活。

# Phase 935 证据 — 锚点多态 + oz9 + 注释/字段 op 细节

## `z5c.t(tl2)` = 注释锚点多态分发（实证）

读 `tl2.j()`（`im` 判别子 @c(4)）→ 实例化：

| 序数 | 类 | 名 | 形式 |
|---|---|---|---|
| 0 | null | NONE | — |
| 1 | `hd1` | CanvasAnchor | inline 结构 `b()` |
| 2 | `lhe` | TextAnchor{textField:qo5, selection:qqe} | 间接表 `d()` |
| 3 | `my3` | EntityAnchor{entities:qo5[]} | 间接表 `d()` |
| 4 | `cwb` | ReplyAnchor{root} | inline 结构 `b()` |

锚子表统一在 @c(6)。未知序数 → `o14.t()` +
`rgc.b(name)` 硬抛。

## `im` = `AnchorKind`

`{NONE=0, CANVAS_ANCHOR=1, TEXT_ANCHOR=2,
ENTITY_ANCHOR=3, REPLY_ANCHOR=4}`。

## `oz9` = `BookmarkState`

`{UNBOOKMARKED=0, BOOKMARKED=1}` 字节枚举——
ln2 f4 / ge8 bookmarked 字段。

## op 细节实名

- `tl2` = **`CreateComment{anchorKind:im@0,
  anchor@1, text}`**
- `ud8` = **`ModifyComment{comment:qo5, anchor,
  text, resolved:bool}`**
- `ra0` = **`AssetCloudPersisted{assetHash:ua0}`**
- `ee8` = **`ModifyPDFField{assetHash, key,
  valueType:ww9, valueString, valueBoolean}`**
- `mqf` = **`UpdateCheckbox{textField:qo5,
  location:cxc, isChecked:bool}`**

## 结论

锚点多态链闭合：im 判别→四锚类型实名；
注释/字段/云持久 op 全名确认。

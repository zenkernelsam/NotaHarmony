# Phase 936 证据 — 四锚类型字段级布局

## `hd1` = `CanvasAnchor`（xwd inline，实证）

20B 内联结构：

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `d()` | `this.I + 0` | page:cxc（12B） |
| `c()` | `this.I + 12` | origin:fqa（8B） |

`toString`: `"CanvasAnchor(page=, origin=)"`。

## `lhe` = `TextAnchor`（cee 表，实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `k()` | c(4) | textField:qo5 |
| `j()` | c(6) | selection:qqe |

## `my3` = `EntityAnchor`（cee 表）

`entities:qo5[] @c(4)`（lv2.H 物化，928 已证）。

## `cwb` = `ReplyAnchor`（xwd inline，实证）

8B 内联：`c()` = root:qo5 @`this.I`。
`toString`: `"ReplyAnchor(root=)"`。

## 布局图

```
CanvasAnchor: | cxc page 12B | fqa origin 8B | = 20B
ReplyAnchor:  | qo5 root 8B                  | = 8B
```

## 结论

四锚类型布局全钉死——两个 20B/8B 内联 +
两个表（qo5/qqe 与 qo5[]）。

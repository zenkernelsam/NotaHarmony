# ADR-1144：编辑器能力接口面（11 iface）

## 状态

已接受（Phase 1200）。

## 决策

`vle` 编辑器 VM 实现 **11 能力接口**（`lo3`/`cma`/`mvc`/
`o65`/`ara`/`jm6`/`q52`/`rd8`/`sn9`/`kv6`/`mp4`，全 public
iface，按笔迹/文本/选择/媒体/undo/视图/工具分簇）→
Harmony editor 控制器分能力方法组（`EditorController`
分 interface/子集）+ `@Observed` 单实现。

## 理由

`implements lo3,cma,mvc,o65,ara,jm6,q52,rd8,sn9,kv6,mp4`
+ `lo3 extends j73{x0(jw6)}` + `o65.f(ry8)`/`sn9.t0()`/
`kv6.b(long)`。

## 后果

Harmony editor 控制器 = 11 能力方法组（笔迹/文本/
选择/媒体/undo/视图/工具）—— API 面分组对齐。

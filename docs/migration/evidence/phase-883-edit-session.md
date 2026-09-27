# Phase 883 证据 — `tzc`/`aa9` 编辑会话层

## 目的

登记 op 写侧的会话/actor 层：`tzc` 编辑会话与 `aa9` 应用
执行器（`decompiled_1.0.3`，classes2.dex）。

## `tzc` = 编辑会话（`extends zac`，Closeable actor）

构造：`tzc(ye9 note, Function0, ya9, qy3)`——`ye9.d()`→
`led{short site}` 为空则 `ve6.i("Note with unresolved editor
site")` 并抛（fail-closed）。

字段（语义登记）：

| 字段 | 类型 | 角色 |
|------|------|------|
| O | short | 本编辑站 siteId |
| P/Q | `bs1` | 双 op-id 计数器（`l96.M(s)`=`bs1(0,site)`）——瞬态/持久序号空间 |
| M | `aa9` | 应用执行器（ops apply/journal actor） |
| N | `b40(qy3, ttf)` | 对端/广播面 |
| K/L | `ai2`/`we2` | `dh3.a.H1(1)` 信箱 + `s01.a` 句柄——actor 收件箱 |
| U | `yc6` | LWW 寄存器宿主（864） |
| R | LinkedHashMap | 挂起项 |
| J | `ye9` | note 聚合：`c()`→ttf、`d()`→led |

方法入口：`v0(eof, map, λbefore, λops, coroutine)` = 通用
变更事务；`B0`/`c0` 为具名变更（fqa/cxc 参数 + map +
eof）——均走 v0 同型管线。

## `v0` 事务流（协程 `gzc` SM）

```
fsi.s(P, Q, now, λops)  → listS uq9 列表
mapB = b(map, eof)      → 删除/变更集
M.c(listS, mapB, λbefore, gzc) → aa9 应用（suspend）
return listS
```

## `aa9` = 应用执行器（`extends zac`）

- `aa9(ya9, ttf)` 构造（ya9+journal/持久面 + note id）。
- `c(list, map, ix4, coroutine)`：JADX 反编译失败（265
  指令单元 suspend SM——登记为「方法体不可恢复」现象，
  语义经 m() 旁证）。
- `m(Collection, Map, coroutine)`：非空 → `l51.i(z99,
  k1a)`——**命令对象经 l51 通道派发**（actor+command 模式）。
- `k1a` = 应用命令（sxe 见 `k1a(o69(ttf), qo5)` = {目标,
  opId}）。

## Harmony 侧

- 编辑会话单写者 ↔ Harmony 的 PageRepository/OpStoreImpl
  顺序化写路径；`bs1` 计数器 ↔ `nextOperationTimestamp`；
  fail-closed site 检查 ↔ siteId 存在性校验。
- `aa9`/`k1a`/`l51` actor+command ↔ Harmony 顺序提交管线
  （同步内存模型，无多 actor）。

## 结论

写侧 actor 层实名登记：tzc（会话/计数器/模型句柄）→
aa9（l51 通道 + k1a 命令应用）→ journal。`aa9.c` 的
JADX 失败如实留档。纯文档+fixture 阶段。

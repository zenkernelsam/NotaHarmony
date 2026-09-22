# 原版证据：撤销/重做合并轨道（vnf.d / pnf / vnf.f,g / haa）— Phase 613

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## 轨道常量（pnf.java:20-31）

```java
pnf pnfVar  = new pnf("INSERT_TEXT", 0, ijg.r0(2, dr3.SECONDS));       // J
pnf pnfVar2 = new pnf("REMOVE_TEXT", 1, ijg.r0(2, dr3.SECONDS));       // K
pnf pnfVar3 = new pnf("CREATE_INK", 2, ijg.r0(10, dr3.MILLISECONDS));  // L
```

- `pnf.J` = INSERT_TEXT，窗口 2 秒
- `pnf.K` = REMOVE_TEXT，窗口 2 秒
- `pnf.L` = CREATE_INK，窗口 10 毫秒

## 轨道指派（vnf.java:56-82，方法 d）

每条 `qnf` 历史项（`UndoAndRedo(undo, redo, coalesceTrack,
clientTimestamp, extras)`，`qnf.java`）携带的轨道由 `uq9.m()`
（`haa` op 类型）决定：

```java
switch (uq9Var.m().ordinal()) {
    case 7: case 8: case 12: case 13: case 14:
        pnfVar = pnf.J;   // INSERT_TEXT
        break;
    case 9: case 10:
        pnfVar = pnf.K;   // REMOVE_TEXT
        break;
    case 15:
        pnfVar = pnf.L;   // CREATE_INK
        break;
    case 11: default:
        pnfVar = null;    // 不可合并
}
```

`haa.java` ordinal → op 类型：

| ordinal | op | 轨道 |
|---|---|---|
| 7 | INSERT_CHAR | INSERT_TEXT |
| 8 | INSERT_STRING | INSERT_TEXT |
| 9 | REMOVE_CHAR | REMOVE_TEXT |
| 10 | REMOVE_CHARS | REMOVE_TEXT |
| 11 | REVIVE_CHARS | null |
| 12 | MODIFY_STYLE | INSERT_TEXT |
| 13 | MODIFY_PARAGRAPH_STYLE | INSERT_TEXT |
| 14 | CLEAR_STYLE | INSERT_TEXT |
| 15 | CREATE_INK | CREATE_INK |
| 其余（CREATE_BLOCK=22 等） | — | null |

要点：样式类 op（12/13/14）与插入共用 INSERT_TEXT 轨道；
REVIVE_CHARS 与其余一切 op 不可合并。

## 分组语义（vnf.java:489-516 f=undo、562-599 g=redo，两法同构）

1. 栈顶项 `qnfVar` 弹出入组（锚点，无条件）。
2. 循环窥视下一项 `qnfVar2`：
   - `qnfVar2.b()`（候选轨道）为 null → 停；
   - `pnfVarB != qnfVar.b()`（候选轨道 ≠ 锚轨道）→ 停；
   - `|qnfVar2.a() - qnfVar.a()| > pnfVarB.a()`（相邻时间差超候选轨道窗）→ 停；
   - 通过 → 弹出入组，锚点更新为该项。
3. `vnf.h()`（607-613）仅刷新 canUndo/canRedo 标志。

时间戳取 `uq9.k()`（op 的 clientTimestamp，op 创建时刻）。

## Harmony 对齐与模型差异

`UndoRedoManager.ets`：

- `coalesceWindow()` 已精确镜像三常量（2000/2000/10）。
- `peekGroup` 语义与 f/g 逐条对应：锚点先入组、候选轨道窗、
  轨道相等、相邻时间差、`window<0`（NONE）断开；另加
  noteId/pageId 边界——Harmony 持久化整本笔记历史且页异步加载，
  属 fail-closed 适配（此前 Phase 已登记）。
- `h()` 等价物为 `commitGroup` 内的 `advanceHistoryRevision()` +
  `latestHistory` 更新。

模型差异：原版富文本编辑器逐 op（键击/样式改）入栈，Harmony
以「一次编辑会话 = 一个 REPLACE_ELEMENT action」提交，过去
REPLACE_ELEMENT 一律 NONE，跨会话快速同向编辑无法合并。

Phase 613 修复：`coalesceTrackFor` 以会话净前后缀 diff 充当
op 类型——仅新增 → INSERT_TEXT、仅删除 → REMOVE_TEXT、
混合 diff / 无文本差 / 带笔画或多块 REPLACE → NONE
（fail-closed）。ADD_ELEMENT ≈ CREATE_BLOCK（ordinal 22 →
null）维持 NONE；`uq9.k()` op 时间戳 ↔ Harmony actionTime
= 会话提交时刻（比较更严，方向安全）。MODIFY_STYLE 类 op
在 Harmony 无对应 UI（格式栏为登记推迟项），不可达分支按
NONE 处理。

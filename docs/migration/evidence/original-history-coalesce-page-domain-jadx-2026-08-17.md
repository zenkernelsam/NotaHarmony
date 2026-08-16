# 原版 Undo/Redo Coalesce 与 Harmony Page Domain 证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/vnf.java`：
  `076F6A267E50BA5565FDA4D6EDEFB8BDE9B05807A328C34D6B6C339E5BDCC157`
- `sources/defpackage/qnf.java`：
  `7BD0D7E468FBF97270A6C8616272E7448A6EB7F275360F4728177F4DC502FF7A`
- `sources/defpackage/pnf.java`：
  `CD376B8E5BBDE870839FDFE7F9436842135B8D14602E5C9826716303FCD3B642`
- `sources/defpackage/tzc.java`：
  `06C32CE45BE4ACBC00055C176F39847BB1C5296F088D2AE0DACD87CB3B7C151B`
- `sources/defpackage/fzc.java`：
  `99E649FDC30D132AEF7251557CEB61F554854D7F93430EA2559E6BD56ACA1CA2`
- `sources/defpackage/dof.java`：
  `02724554B987850EE47A96A0A4FB5D64DF9C00A14E9EDA6F3E8B7F1CE9F49D91`
- `sources/defpackage/k1c.java`：
  `9E0C29D4C0A7513A3542AE9A29092487B25E69331051A89626590ADF73057183`
- `sources/defpackage/i1c.java`：
  `931365310D1AA4CF2D2886B0AFF29FC4A7978B2CCEFBF3F3199401FE209FC8F8`

## 1. 原版只按相邻 track 与时间窗扩展 group

`vnf.java:442-518`（一方向）与 `:525-601`（另一方向）先取栈顶 `qnf`，随后反复查看相邻项：

```java
qnf qnfVar2 = (qnf) au1.o1(arrayList);
if (qnfVar2 != null && (pnfVarB = qnfVar2.b()) != null) {
    long jA = qnfVar.a();
    long jA2 = qnfVar2.a();
    long jS0 = ... abs(jA - jA2) ...;
    if (pnfVarB != qnfVar.b() || zq3.c(jS0, pnfVarB.a()) > 0) {
        break;
    }
    qnfVar = (qnf) arrayList.remove(arrayList.size() - 1);
    arrayList3.add(qnfVar);
}
```

比较基准每次更新为刚弹出的相邻项，所以这是 **pairwise adjacent window**，不是拿最旧项与最顶项做总跨度判断。
例如 CREATE_INK 时间为 100/110/120ms 时可三条合并，尽管首尾相差 20ms；100/111/120ms 则在 111→100
的 11ms 缺口处停止。

上述方法没有读取 page identity，也没有显式页面边界条件。不能把 Harmony 新增的 page domain 伪称为原版已有
判断。

## 2. 原版 track 与窗口

`pnf.java:18-29` 定义三条 track：

- `INSERT_TEXT`：2 秒；
- `REMOVE_TEXT`：2 秒；
- `CREATE_INK`：10 毫秒。

`qnf.java:5-21` 的 `UndoAndRedo` 字段为 undo、redo、`pnf coalesceTrack`、client timestamp 与 extras map；
该对象自身没有 pageId。

## 3. 多动作聚合保持 Undo/Redo 的方向语义

`vnf.a(List)` 在多于一项时把它们包装成一个新的 `qnf`：

- Undo 操作通过 `k1c` 反向视图展平；`k1c/i1c` 明确从底层 `ListIterator.previous()` 迭代；
- Redo 操作按传入 list 正向展平；
- 新聚合项不再继续 coalesce，但保留传入末项的 timestamp/extras。

Harmony 没有把 group 压成新对象，而是以 `HistoryMove[]` 按实际施加顺序逐项 durable replay；Undo 为栈顶到
栈底，Redo 在 Undo 后形成相反栈序并按最旧到最新重放，结果与原版方向一致。

## 4. 原版 history owner 不是 page identity

`tzc.java:14-26,62` 的一个 session 持有 `LinkedHashMap R`。`fzc.java:50-65` 用 `eofVar` 查该 map，缺失时
创建 `new vnf()`；`dof` 只是一个空的 editor-owner marker。静态证据表明 history 由 session/editor owner
隔离，而不是由 `qnf` 的 pageId 隔离。

CREATE_INK 只有 10ms 窗口，真实页面切换通常会自然打断连续 Ink；但这只是原版 UI/时序下的可达性判断，不是
可用于移植的显式数据不变量。

## 5. Harmony 旧实现为何仍会出错

Harmony 采用可持久恢复的全笔记时间序历史，每个 `UndoableAction` 带 `noteId/pageId`，页面内容却由
`NoteCanvasView` 异步逐页加载，`saveHistoryGroup()` 也只接受一个具体 pageId 并在该页事务内重放整个 group。

修复前 `UndoRedoManager.peekGroup()` 仍只比较 track/time，因此恢复记录或极端快速切页可能生成跨页 group。
`performHistory()` 只有 `isSinglePageElementGroup()` 为真才走整组事务；跨页 group 会静默落入后续单动作分支，
只施加并提交顶部动作。这样一次用户 Undo 不再等价于原版已经选出的 coalesced group。

## 移植结论

- 保留原版三种 track、10ms/2s 窗口、inclusive 比较与 pairwise anchor 更新。
- 在 manager 形成 group 时额外要求相邻动作 `noteId + pageId` 完全相同；这是 Harmony 异步/持久恢复架构的
  page-domain 安全不变量，不冒充原版字段。
- UI 对任何仍违反 note/page/type domain 的多动作 group fail closed，不得再次退化成只移动顶部一条。
- 同页 group 继续由 `writeHistoryGroupLocked()` 在一个 SQLite transaction 中逐步写 operation/revision，任一步
  失败整体 rollback；manager 只有 durable apply 成功后才移动完整 group。
- 不按 action type 强行收窄 track：持久恢复后的文本类原版 operation 会物化成
  `PERSISTED_PAGE_MUTATIONS`，仍需保留 INSERT_TEXT/REMOVE_TEXT coalesce metadata。页面动作和特殊复合动作由
  UI group-domain guard 拒绝异常合并。

## 验证边界

ArkTS fixture 和桌面 replay 能证明同页 pairwise 顺序、跨页/跨 note 截断、Undo/Redo group 顺序、UI fail-closed
以及同页 durable transaction。仍需设备验证快速连画、Undo/Redo 后自动切页、应用重启后的恢复历史和连续点击
期间的交互反馈。

# Phase 864 证据 — 物化实体模型登记（ly3/qg2/yy3/mz9 + 7 Impl + yc6 寄存器）

## 目的

线层（856–862）登记了字节协议。本阶段登记**物化层**：op 流如何
折叠成实体 —— 实体接口栈、7 个 `*Impl` 物化类、`yc6` 赢家寄存器。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### 接口栈

```
ly3 (qg2)          — 实体基：O()→uq9 归属操作；getId()=O().l()→qo5；
                     e()/f()v09/g()long；I()=O().o()非空即 synced
qg2                — u(aVar)：将当前态再序列化为新 Op（重放/undo）
yy3 (ly3,qg2)      — builder() + E() generation
mz9 (ly3)          — Page 契约：B()→nz9 background、l()→bookmarked、
                     p()→pageInAsset、v()→cxc 位置、z()→ln2 payload
```

### 物化实现（`implements` 各接口，7 类）

| 类 | Impl | 接口 |
|----|------|------|
| wz9 | PageImpl | mz9（+yy3 via mz9） |
| s06 | InkImpl | yy3,be5,ly3,bf0 |
| vz9 | Page builder | mz9,xy3 |
| m4c | RichTextImpl | qg2,o4c,t3c |
| n5d | ShapeImpl | yy3,bf0,be5,m4d |
| l85 | GroupImpl | yy3,h85 |
| gkb | RecordingImpl | yy3,yjb |

**每个实体携带来源 Op**：`wz9` 构造即取 `uq9`（metadata）+
`ln2`（CreatePage payload）+ pageInPayload 序号，再叠三个
`yc6` 寄存器（background/bookmarked/pageInAsset），
`nti.g(uq9.l(), i)` 从 op-id+序号派生 `cxc` 位置标识。

### `yc6` — 赢家寄存器宿主

`xj2.v(this.e, n[0])` 委托读寄存器当前赢家（`.K` 槽）；
`wz9.l` = `f.K == oz9.BOOKMARKED` —— bookmarked 由寄存器
赢家物化；`wz9.m` = pageInAsset 寄存器值 − sw9.n() 页内偏移。

### 再序列化

`wz9.u(aVar)` → `haj.a(null, nz9, 1, oz9 winner, 16)` —— 把当前
物化态折回一个新 CreatePage 变体 Op（undo/重放用）。

## Harmony 侧（`note/src/main/ets`）

- `OperationIdentity`（`data/OperationIdentity.ets`）：
  siteId u16 + timestamp u32 校验（`MAX_EDITOR_SITE_ID`/
  `MAX_OPERATION_TIMESTAMP`）、`op:<ts>:<site>` 编码 ↔ qo5。
- `OpStoreImpl`：op 行存 `op_id`+`client_time`+`operation_index`，
  提供来源溯源。
- `OriginalNoteBundlePageIdentity`/`BootstrapPageState`：
  赢家寄存器语义实现（bookmarkWinner/winner 行、LWW 比对、
  物化写 `page_info.bookmarked` 等 —— 747+ 阶段已落地）。
- 元素层不经实体-Op 指针，而是 op 行 + 物化表 + 赢家行三件套 —
  持久化式等价。

## 结论

物化模型登记完毕：接口栈（ly3→qg2→yy3→mz9）、7 Impl、yc6 寄存器、
u() 重序列化全部留档；Harmony 以 op_id 溯源 + 赢家行物化等价覆盖。
本阶段纯文档+fixture，无源改动。

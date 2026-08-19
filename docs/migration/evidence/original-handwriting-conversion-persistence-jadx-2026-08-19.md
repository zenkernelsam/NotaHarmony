# 原版 Convert-to-Text 原子持久化证据（2026-08-19）

## 1. 范围与只读基准

本证据承接 Phase 276 的纯逻辑计划器，聚焦原版 Convert-to-Text 的落盘顺序、Text Block 几何和
Harmony 为该三步 operation 增加的原子 RDB/history 基础设施。Desktop 仅用于读取
`decompiled_1.0.3`；全部实现、fixture、Replay、ADR 与报告均位于正式仓
`C:\HarmonyProject\NotaHarmony`。

原版源码根目录：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 关键行 | 证明 |
|---|---|---:|---|
| `xsc.java` | `41C4BD1D24F50E04C095B319BA4B1F37CD04ACD9B43B744DF67D78F89FFF5BB8` | 122-167, 192-208 | 单页门禁、union bounds、每轴最小 8、page frame origin |
| `bt1.java` | `A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA` | 51-63 | 同一 `xq9` callback 内严格执行 DELETE → CREATE → INSERT |
| `u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | 538-552 | Text Block 创建显式消费 page、relative origin、size，未知 page 失败 |
| `s5j.java` | `D52D1095314843F53AB8866BF4C06D045E6C0AA5C7A1A531A1D12D5F7E0A3813` | 606-614 | `INSERT_STRING` 以创建出的 Block identity 写入完整字符串 |
| `haa.java` | `C5B4281AE04AEE82EAB044B4C01FD960A22032FCEF5274F7BD8B33B64C54E126` | 26, 40, 43 | 原版 payload type：INSERT_STRING=8、CREATE_BLOCK=22、DELETE_ENTITIES=25 |

## 2. 原版不可省略的 transaction 语义

`bt1.invoke()` 的 case 2 收到一个 `xq9` transaction 对象，并在该对象上连续执行：

```text
xq9Var2.a(... u5j.l(... selected Ink ...))
qo5 newText = xq9Var2.a(... u5j.f(... TEXT, page, relativeOrigin, size ...))
xq9Var2.a(... s5j.i(... recognizedText, newText ...))
```

三步的顺序不是可交换的：DELETE 先撤去源 Ink；CREATE 产生后续 INSERT 所引用的 Block identity；
INSERT 必须引用该精确 identity。`haa` 同时确认三步 wire payload type 分别为 25、22、8。

`xsc.j()` 对所有选中实体的 world bounds 求 union，宽/高不足 8 时居中扩展，再与当前 page frame
origin 一起返回。`bt1` 以 `selectionTopLeft - pageOrigin` 传给 `u5j.f()`；`u5j.f()` 又显式接收 page、
origin 与 size，因此 Harmony 不得把 page world origin 重复写进 Text transform，也不得省略 size。

## 3. Phase 277 与原版的对应关系

### 3.1 同一 SQLite transaction、同一 revision batch

`StrokePersistence.commitOriginalHandwritingConversion()` 在一个 `beginTransaction()/commit()` 边界内：

1. 重新读取 live page 和完整当前快照；
2. 将每条 source Ink 的持久化字节与识别请求快照逐字节比较；
3. 分配并应用 type-25 DELETE_ENTITIES；
4. 分配并应用 type-22 CREATE_BLOCK(TEXT)；
5. 分配并应用 type-8 INSERT_STRING；
6. 只调用一次 `OriginalPageMutationBatch.flush()`；
7. 验证 revision 恰好增加 1、源 Ink 全部消失、Text 几何/文字精确一致；
8. 写入 HWC1 history companion 与最终 snapshot/search projection 后提交。

任一步 deferred、身份冲突、source stale、Text 状态偏离、history 写入失败或 revision 竞争都会 rollback。
三类原版 outbound row 仍各自保留真实 operation identity；HWC1 仅是 Harmony durable editor-history
companion，不冒充原版第四种 wire operation。

### 3.2 一个 batch 合并 Ink/Text 搜索失效

Phase 277 为 `OriginalDeleteEntitiesOperationApplier` 增加 batched entity visibility 路径，并让
DELETE、CREATE、INSERT 三个 reducer 共用一个 `OriginalPageMutationBatch`。batch 按 page 合并变化：

- source Ink 删除标记 `SearchItemType.INK` 失效；
- Text 创建/写字标记 `SearchItemType.TEXT_BLOCK` 失效；
- page revision 只从 `N` 推进到 `N+1`，不因三个 operation 变为 `N+3`。

### 3.3 HWC1 与可逆 visibility

HWC1 保存完整 `PageMutationOpPayload`、精确 source Ink IDs 和创建出的 Text ID。decoder 不只信任
外层 kind/ID，还调用 `decodeStoredPageElement()` 校验 payload 内嵌 discriminator 与实体 ID。

Undo/Redo 不重新创建或销毁原版实体，而是各写一条 type-25 visibility operation：

```text
Undo: hide Text, restore every source Ink
Redo: hide every source Ink, restore Text
```

移动前先用 HWC1 的完整 before/after 快照 replay 校验当前页面；移动后再次读取 materialized page、验证
revision `+1`，随后在同一 transaction 写 HWC1 UNDO/REDO history companion。失败时持久层不推进栈。

## 4. Harmony 安全门禁

- source 必须为 canonical original Ink identity，已完成、非 highlighter、非 partial eraser且不重复；
- source 请求快照经 persistence codec clone，再与数据库 payload 逐字节比较，迟到结果不能删除已变化的 Ink；
- origin/width/height 及 `origin + size` 必须可表示为有限 Float32；width/height 仍至少为 8；
- recognized text 必须非空，并经生产 `encodeOriginalInitialInsertString()` 的 UTF-8/1 MiB 预算校验；
- 创建 Text 后精确校验 identity transform、Float32 origin/size、world bounds 和完整字符串。

## 5. 明确未闭环的产品层

Phase 277 提供的是可调用的持久化与 durable history 基础设施，不是用户可见功能。当前仍没有：

- 真实 OCR provider；
- Locale/global handwriting preference adapter；
- SelectionOverlay “转文字”入口；
- 生产 page-frame、页面可见性与 source fingerprint 采集/调度；
- 设备正确率、延迟、内存、错误提示及交互体验验收。

因此不得将本阶段描述为“手写转文字已上线”。

# Phase 1309 证据 — CRDT 线格式保真度

来源：`data/{OperationIdentity,OriginalOperationEnvelope
Encoder,OriginalSyncedOperationFlatBuffer,Incoming
OperationSyncCoordinator}.ets`。

## 线格式保真（FlatBuffer 兼容）

- `OriginalSyncedOperationFlatBuffer` +
  `OriginalOperationEnvelopeEncoder` —— Harmony **读写
  原版 FlatBuffer op 信封**（`parseOriginalSynced
  OperationEnvelope`）。
- `ORIGINAL_*` op = 解码的原版 `haa` op —— 线格式
  与原版互通。

## 排序保真（`OperationIdentity`）

```
timestamp: number; siteId: number;
// "The original packs timestamp/site into a 64-bit integer"
// "exc.A0 in the original compares the signed int
//    timestamp first, unsigned site second"
compareOriginalSequenceIdentity(l, r):
  toJavaInt(l.timestamp) - toJavaInt(r.timestamp)  // signed int
  → siteId unsigned compare
```

→ **逐位复刻原版 `exc.A0` 比较器**（signed-int
timestamp 优先、unsigned siteId 次之）+ 64-bit
packing —— op 排序与原版逐位一致（对应 `tmf`
orderable long）。

## 同步协调

`IncomingOperationSyncCoordinator`：`AsyncMutex` 互斥 +
`receiveOpsEvent`/`replayOpsBundle`/`replayDeferredBundle`
+ `validateOperationIdentity` + discard/apply 计数 +
`localSiteId`+`peerInteractions` —— site-ID CRDT 同步。

## 语义

Harmony CRDT = **线格式+排序保真**（FlatBuffer 信封
+exc.A0 比较器+64-bit packing+site-ID 互斥同步）——
与原版互通；本地 op 超集是增量非替代。

## Harmony 决策

线格式/排序保真 → 与原版同步互操作；本地 op 扩展
（ORIGINAL_ 桥接+元素级）分层叠加 —— CRDT 线兼容
语义保真。

## 产出

- fixture `d02-crdt-wire-fidelity.mjs`（10 断言）。
- ADR-1253；中文报告。

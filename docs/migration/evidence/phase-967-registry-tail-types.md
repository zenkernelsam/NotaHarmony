# Phase 967 — z0c 注册表尾部 8 类型定名（注册表 100% 关闭）

来源：`decompiled_1.0.3/sources/defpackage/{vt9,q89,nz9,sw9,sdf,ua0,p9,k3a}.java`

## 定名结果

| 类 | 语义 | 布局 |
|----|------|------|
| `vt9` | **OpsBundle** | `{ops:uq9[]@f0, schemaVersion:short@f1}` — ops-blob 外层 |
| `q89` | **NoteMutationResponse** | `{noteId, acks}` — 服务端变更响应 |
| `nz9` | **PageBackground** | `{paper,pdf,rotation,size,margins}` — ln2/ge8 的 f2 载荷 |
| `sw9` | **PDFAsset** | `{metadata,layoutBehavior,totalPageCount,pagesConsumed,pageOffset,cropBoxes}` |
| `sdf` | **TransientInteraction** | `{interactionId,timeout}` — uq9 f6 载荷 |
| `ua0` | **AssetHash** | **64B 内联结构：8×long @0..56**（c()..j()） |
| `p9` | **AcknowledgeAppendedOpsEvent** | `{acks:vq9[]@f0}` — server→client 事件 |
| `k3a` | **Paper** | `{flair,flairSpacing,flairBleeds,flairCentered,backgroundColor,legacyPaperIndex...}` — n2d/rl2 纸张 |

## 细节

- `ua0.h()=getLong(I+40)`、`i()=+48`、`j()=+56` → 8 个 long，
  64 字节（SHA-512 长度）——资产哈希 512bit。
- `vt9.k()` 读 `c(6)` short = schemaVersion；`j()`/`l()`
  读 `c(4)` = ops uoffset 向量 + 逐元素 uq9。
- `p9` 仅单字段 c(4) = `vq9` OpAck 向量。
- `sw9.cropBoxes` = `bmb` 矩形向量（PDF 页裁剪）。
- `k3a` Paper 字段与 nz9.paper / n2d SetPaper / rl2.paper
  三处引用一致。

## 意义

至此 z0c 注册表 **80 项全部定名**：15 xwd 结构 +
65 cee 表（31 op + 信封/ack/bundle/事件/setter/def/
资产/元数据）。写侧注册表调查**关闭**。

## 验证

`d02-registry-tail-types.mjs` 静态断言。

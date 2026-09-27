# Phase 944 证据 — `sg5` 草稿池 + `jmf` + `w0j`

## `sg5` = 序列化 ThreadLocal 草稿池（实证）

kotlin-reflect `v1b` 委托属性数组登记全部
可复用 scratch 实例——**KProperty 名直接泄露
原 Kotlin 语义名**：

| Holder | 类型 | 真实名 |
|---|---|---|
| ID_HOLDER | qo5 | **Id** |
| SEQ_ID_HOLDER | cxc | **SeqId** |
| STYLE_MAP_HOLDER | yyd | **StyleMap** |
| RECORDING_SEGMENT_PROVIDER | ukb | RecordingSegment |
| POINT_HOLDER | fqa | **Point** |
| SIZE_HOLDER | qed | **Size** |
| MODIFY_POSITION_HOLDER | ie8 | **ModifyPosition** |
| OP_ACK_HOLDER | vq9 | **OpAck** |
| OP_HOLDER | uq9 | **Op** |
| DUPLICATE_OP_HOLDER | ? | DuplicateOp |
| offsets/nestedOffsets/usingOffsetsHolder | List+AtomicBoolean | — |

包路径实证 `com.gingerlabs.notability.core.
flatbuffers.{Id,SeqId,StyleMap,RecordingSegment,
Point,Size,ModifyPosition,DuplicateOp,OpAck,Op}`
——原生名交叉确认！

`cz8(type,bh4(idx))` c..n = 带类型+槽位的
provider；`d1 o` = 空迭代器哨兵。
`sg5.a()`→qo5 scratch、`b()`→cxc、
`g(List)`→ix4 向量写入器、`f(builder,exc)`=写。

**目的**：热序列化路径零分配——写端反复用
同一组 struct 实例填 builder。

## `jmf` = 路径向量提供接口

`interface jmf`——o0j.a 的 jmfVar×3 即中心/
自定义/填充路径的 ByteBuffer 提供器抽象。

## `w0j` = ModifyPosition(ie8) 工厂+写器

- `a(qo5,cxc,fqa,k2d,y2d,xgb,int)` → ie8
- `d(ie8,builder)` 序列化、`e(builder,...)` 字段写
- `b/c` Bundle 读写（Android 持久化）

## 结论

sg5 KProperty 名反向确认整套类型真名；
写端草稿池机制钉死。

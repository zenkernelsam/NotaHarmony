# Phase 968 — 注册表尾部写器解剖（x6j/w6j 等）

来源：`decompiled_1.0.3/sources/defpackage/{x6j,w6j,q5j,vv7,fag,j7j,kvi,qqi}.java`

## 1. `x6j.b` = vt9 OpsBundle 写器

与 q4j.c 同一 ops-vector 模式：`sg5.n` OP_HOLDER +
`wj9(1,...)` 元素提供器 + `sg5.e()` CAS + c()/d() 双缓冲
+ `ree.a` 逐 op + `D(4,iJ,4)` 逆序推偏移；然后 C(2) 写
f0=ops 向量 + f1=schemaVersion。

## 2. `w6j.c` = vq9 **OpAck 写器**

```java
qo5 id = vq9.k(); uq9 op = vq9.m(); String err = vq9.l();
Boolean ack = vq9.j();
opOff   = op  != null ? zq9.d(op, a)   : null;  // 内嵌完整 op!
errOff  = err != null ? dbj.c(err, a)  : null;
aVar.C(4);
j(0, rh8.O(id));                 // f0 = opId qo5 必需
if (opOff != null) h(1, opOff);  // f1 = 内嵌 op（回声）
if (errOff != null) h(2, errOff);// f2 = errorMessage
if (ack != null) { l=true; a(3,ack,false); l=false; } // f3 三态
z(iN,4);                          // required: f0
```

**OpAck 携带完整回显 op**（f1 内嵌 uq9 经 zq9.d 序列化）
——服务端确认/失败回执协议。

## 3. 其余尾部写器（switch 名录，Phase 962/966 已证）

| 写器 | 类型 | 语义 |
|------|------|------|
| `q5j.b` | `q89` | NoteMutationResponse |
| `vv7.L` | `nz9` | PageBackground |
| `fag.n0` | `k3a` | Paper |
| `j7j.c` | `sw9` | PDFAsset |
| `kvi.f` | `p9` | AcknowledgeAppendedOpsEvent |
| `qqi.d` | `sdf` | TransientInteraction |

## 4. 意义

- ops-vector 写模式第三次出现（q4j/x6j/vej）——
  `ree.a`+CAS 双缓冲为全局嵌套写规范。
- OpAck 内嵌 op = 协议回执语义实证：ack 不止 ID，
  还带 op 回显与错误消息。

## 5. Harmony 对齐

Harmony 原稿 ack 语义目前仅本地标记；内嵌回显 op
属服务端协议（fail-closed 范畴，原稿线型已记录）。

## 6. 验证

`d02-tail-writers.mjs` 静态断言。

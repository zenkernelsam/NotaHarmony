# ADR-0859 — 字符 op 四表（e46/f46/qub/f2c）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `e46` InsertChar{location:cxc, textField:qo5,
  unicodeScalar:mmf UInt}；`f46` InsertString
  {location:cxc, string, textField:qo5}；
  `qub`/`f2c` Remove/ReviveChars{locations:cxc[],
  textField:qo5}。
- cxc 12B 内联结构向量寻址 `(i*12)+f(v)`；zq9 注册
  INSERT_CHAR/INSERT_STRING/REMOVE_CHARS/REVIVE_CHARS。
- 文本为 **cxc 位置 ID 锚定的墓碑式 CRDT**——并发
  插入位置稳定，删除/复活同载体。

## Harmony 决策

文本 op 编码对齐：cxc 锚定 + mmf Unicode 标量 +
cxc[] 删除/复活集。

## Parity 状态

等价。

## 验证

- `d02-char-ops-quartet.mjs`：13/13 通过。
- 全量 Replay 788 文件绿，见 Phase 915 提交。

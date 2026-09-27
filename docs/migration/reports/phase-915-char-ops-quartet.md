# Phase 915 报告 — 字符 op 四表实名

## 范围

文本字符 op 族实名 + CRDT 模型确认。纯审计。

## 原版发现

- e46/f46/qub/f2c = InsertChar/InsertString/RemoveChars/
  ReviveChars；统一 cxc 位置锚定 + qo5 textField。
- cxc 12B 内联结构向量寻址实证；unicodeScalar=UInt。
- 删除/复活同构墓碑集 → 文本 CRDT 证据闭合。

## Harmony 核对

文本 op 编码对齐。

## 产出

- 证据：`phase-915-char-ops-quartet.md`
- Fixture：`d02-char-ops-quartet.mjs`（13/13）
- ADR-0859；全量 Replay 788 文件绿。

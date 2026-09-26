# ADR-0743 — 文档-代码一致性清扫（fixture 引用面）

日期：2026-09-29
状态：已修正并登记（不改 Harmony 功能源码）
证据：`docs/migration/evidence/phase-799-consistency-sweep.md`
Replay：`docs/migration/replays/d02-consistency-fixture-references.mjs`

## 背景

全面交叉引用扫描发现：(a) feature-note-tail fixture 对不
存在的 ADR-0513 文件做软引用且断言恒真；(b) ADR-0670
两处陈旧引用；(c) 9 个 fix 提交回归 fixture 无文档挂接。

## 决策

- 软引用改实：读 ADR-0658（协作面 fail-closed 登记）
  并断言实质内容。
- ADR-0670 引文修正为 ADR-0658。
- 9 个孤儿 fixture 入册为独立回归 fixture（保留在套件
  中），防回归 fixture 钉住引用面规则。

## 后果

- fixture 引用面闭合：任何 fixture 必须被文档引用或入册。
- `|| true` 空断言模式被 fixture 级规则禁止。

# Phase 937 报告 — Uuid 线型 + 路径字节迭代器

## 范围

`utf` 布局 + `di7`/`ei7` 迭代器偏移。纯审计。

## 原版发现

- utf=Uuid 16B{bitsHigh@0,bitsLow@8} MSB-first。
- di7=hmf 零拷贝迭代器，wd8 读 g(20/22/24)、
  dm2 读 g(24/26)、gd 读 g(6/8)；ei7 读 dm2
  g(22)。`g(int)`=切片访问器证实路径向量
  为原始字节。

## 产出

- 证据：`phase-937-utf-di7.md`
- Fixture：`d02-utf-di7.mjs`（10/10）
- ADR-0881；全量 Replay 810 文件绿。

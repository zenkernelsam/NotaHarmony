# Phase 952 报告 — `vej` 完整面

## 范围

vej.java 全部 18 个静态方法分类。纯审计。

## 原版发现

- `a`/`q` = RemoveChars(qub) 工厂/写器对——工厂含
  `d()` 反读自检 + `ybg.c` 校验 + `rh8.q` builder 归还。
- `b`–`r` = 富文本光标移动契约：行上下(di3 remembered-x)、
  BreakIterator grapheme/词导航、hqe={paraIdx,offset} 位置、
  t4g=Affinity{Start,End}。
- Harmony 用原生 TextArea + 扁平 caretOffset——光标层平台委托。

## 产出

- 证据：`phase-952-vej-cursor-helpers.md`
- Fixture：`d02-vej-cursor-helpers.mjs`（22/22）
- ADR-0896；全量 Replay 825 文件绿。

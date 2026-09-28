# Phase 956 报告 — `cee`/`xwd` 读侧原语层

## 范围

cee.java + xwd.java + x82/zq6 UTF-8 层。纯审计。

## 原版发现

- `xwd` = 内联结构基类 {I,J}，定长直读。
- `cee` = 表基类：d=vtable 解析、c(N)=槽查（c(4+2n)=fieldN）、
  e=内联 UTF-8（x82.A/z/y + 畸形/越界护栏）、f/i=向量、g=零拷贝。
- 全部历史 c(N) 读侧断言的理论根基坐实。

## 产出

- 证据：`phase-956-cee-xwd-primitives.md`
- Fixture：`d02-cee-xwd-primitives.mjs`（22/22）
- ADR-0900；全量 Replay 829 文件绿。

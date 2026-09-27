# Phase 940 报告 — rl2 CreateBlock 21 字段图

## 范围

最大 op 表 rl2 全槽位钉死。纯审计。

## 原版发现

- 21 槽：cz0+ty0+cxc+fqa+Float+qed×2+ive+
  bool+tmf+dp5+bmb+String×2+hu1+k3a+bool×3+
  vy7+bool。
- 语义分组：变换头 f2-f8 + 内容组（按 cz0
  判别）+ 变换尾。

## 产出

- 证据：`phase-940-rl2-block.md`
- Fixture：`d02-rl2-block.mjs`（22/22）
- ADR-0884；全量 Replay 813 文件绿。

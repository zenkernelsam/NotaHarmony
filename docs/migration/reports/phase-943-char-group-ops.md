# Phase 943 报告 — 字符/组 op 偏移图

## 范围

e46/f46/pub/qub/f2c/cm2/vd8 偏移。纯审计。

## 原版发现

- Insert 对：{location:cxc@0, 内容@1, textField:qo5@2}；
  Remove/Revive 对：{location(s)@0, textField@1}。
- cm2={members@0}；vd8={group 必需@0,members@1}。
- zq9 全注册表读端偏移至此 100% 覆盖。

## 产出

- 证据：`phase-943-char-group-ops.md`
- Fixture：`d02-char-group-ops.mjs`（14/14）
- ADR-0887；全量 Replay 816 文件绿。

# ADR-0887 — 字符/组 op 偏移图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- Insert 对：e46/f46 = {location:cxc@0, content@1,
  textField:qo5@2}；Remove/Revive 对：pub/qub/f2c =
  {location(s)@0, textField:qo5@1}。
- `cm2` CreateGroup{members:qo5[]@0，0 成员拒绝}；
  `vd8` ModifyGroup{group:qo5@0 必需, members@1}。
- zq9 全注册表读端偏移至此 100% 覆盖。

## Harmony 决策

偏移对齐。

## Parity 状态

等价。

## 验证

- `d02-char-group-ops.mjs`：14/14 通过。
- 全量 Replay 816 文件绿，见 Phase 943 提交。

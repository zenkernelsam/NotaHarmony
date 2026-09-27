# ADR-0858 — `cm2`/`vd8` 分组 op 读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `cm2` = CreateGroup{members:qo5[]@0} 单字段；
  校验 `"Cannot create a group with 0 members"`；
  `haa.CREATE_GROUP`。
- `vd8` = ModifyGroup{group:qo5@0 必填, members:qo5[]@1}；
  `haa.MODIFY_GROUP`。
- qo5 以 8B 内联结构存向量（`(i*8)+f(v)` 寻址）。

## Harmony 决策

分组 op 编码对齐：内联结构向量 + 必填断言 +
零成员拒绝。

## Parity 状态

等价（871 shape/group 族四表读侧全闭）。

## 验证

- `d02-group-cm2-vd8.mjs`：13/13 通过。
- 全量 Replay 787 文件绿，见 Phase 914 提交。

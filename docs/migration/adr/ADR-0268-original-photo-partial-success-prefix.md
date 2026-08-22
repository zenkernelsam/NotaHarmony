# ADR-0268：多图照片部分失败保留成功前缀

- 状态：Accepted（Phase 290，2026-08-23）
- 范围：Harmony PhotoViewPicker 多图导入失败路径、UI 状态与 Undo history
- 相关：ADR-0258、ADR-0261、ADR-0267

## 决策

多图导入继续逐张使用 durable SQLite transaction，不伪装跨图 rollback。第一张失败时没有成功前缀，
调用方保持整批失败语义；中途失败时，已提交图片构成显式成功前缀：安装到当前页、选中、重绘，并作为
同一个 ADD_ELEMENTS action 进入 Undo/Redo。

成功前缀返回 `{ insertedCount, totalCount }`。只有 `insertedCount === totalCount` 才清除
`saveFailed` 并保持完全成功路径；严格前缀只显示一次 localized partial-failure toast，不再触发通用
save-failure 状态或双重反馈。剩余失败由 hilog 记录。

## 原版与平台边界

原版 `tf9.B` 在进入逐 URI ingress 前对列表做 all-or-nothing 校验；该边界已由 Harmony ingress 保留。
原版证据未提供本阶段涉及的 SQLite/history companion 失败分支，因此不推断跨图 rollback 能力。Harmony
已 durable 的前序事务不能安全撤销，显式前缀比隐藏成功结果更接近用户可见事实。

## 验证边界

专项 Replay 固定严格非空前缀、单次部分失败 toast、首张整批失败、逐图事务和 Undo 安装顺序。ArkTS fixture
注册进既有套件；真实设备多选失败注入、权限中断和大批量性能仍开放。`T-042` 继续保留为 Goal 最后一项。

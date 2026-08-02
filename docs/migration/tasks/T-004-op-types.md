# T-004 操作流类型与存储接口

## 目标

创建 op 流相关类型（OpType 枚举、Op 接口、OpSerializer 接口）和 OpStore 存储抽象接口。

## 参考

- 知识库：REVERSE_ANALYSIS.md §21（op 流持久化：ClientOp 表、元素 schema、序列化 zli）
- 契约：`docs/migration/phase-1-data-model.md` §3.5 和 §3.9

## 实现要求

### 创建文件

1. `note/src/main/ets/core/model/OpTypes.ets`
2. `note/src/main/ets/core/op/OpStore.ets`

### OpTypes.ets 必须导出

- `enum OpType`（14 个值，见契约 §3.5：CREATE_PAGE=0 到 REDO=41）
- `interface Op { opId: string; noteId: string; opType: OpType; payload: Uint8Array; clientTime: number }`
- `interface OpSerializer { serialize(op: Op): Uint8Array; deserialize(data: Uint8Array): Op }`

### OpStore.ets 必须导出

- `interface OpStore`（5 个方法：appendOp / getOps / getOpsSince / deleteOps / getOpCount，全部返回 Promise）

### 依赖

- OpStore.ets: `import { Op, OpSerializer } from '../model/OpTypes'`

### 鸿蒙特有约束

- 禁止平台 import。
- Op.payload 使用 `Uint8Array`（ArkTS 标准二进制类型）。
- 所有异步方法返回 `Promise<T>`。
- 枚举值留间隔（页面 0-3，元素 10-13，擦除 20-21，笔记 30，撤销 40-41），便于后续扩展。

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] OpType 枚举包含 14 个值
- [ ] OpStore 所有方法签名为异步（Promise）
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-004-完成.md`

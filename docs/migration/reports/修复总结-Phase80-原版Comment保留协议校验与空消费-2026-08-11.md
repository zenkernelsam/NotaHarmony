# Phase 80 修复总结：原版 Comment 保留协议校验与空消费

日期：2026-08-11

## 问题

payload type 30 `CREATE_COMMENT` 与 type 31 `MODIFY_COMMENT` 尚未接入统一生产路由，收到后会永久
deferred 并阻塞同一笔记后续队头。仅看 schema 容易误以为应新增完整评论数据库和 UI，但原版 1.0.3
是否真正消费这两个 payload 必须由 reducer 证据决定，不能根据类型名称猜测。

## 原版证据

- `haa/zq9/wq9/fsi.P`：30/31 分别是 CREATE_COMMENT/MODIFY_COMMENT，二者均为 durable。
- `tl2/daj/z5c.t/im`：create 支持 CANVAS、TEXT、ENTITY、REPLY 四种 anchor union；anchor 不可为 NONE，
  text 必须非空。Canvas/Reply 是 union uoffset 指向的 struct，Text/Entity 是 table。
- `ud8/k0j/z2d/z1d`：modify 的 comment ID required；optional anchor 是直接 inline CanvasAnchor，text 与
  resolved 是可显式置 null 的 setter table，三项至少出现一项；bool reader 对任意非零 byte 返回 true。
- `v69/fsi.F/fsi.K`：原版 1.0.3 没有 30/31 model reducer；两类 dependency/target 都为空，合法 payload
  校验后被有序消费但不建立实体、register 或 UI state。全包搜索也没有 reader/writer 以外的 `tl2/ud8` consumer。

## 修复

- 新增 `OriginalCommentOperation.ets`，完整解码四种 create anchor、comment ID、CanvasAnchor、TextSelection、
  entity set、nullable text/resolved setter；校验 identity/SeqId、finite point、UTF-8、空文本、空修改和未知字段。
- 为共享 FlatBuffer reader 新增 bounded indirect inline struct 读取，正确区分 create union 的间接 struct 与
  modify anchor 的直接 inline struct，避免把 Canvas/Reply 错当 table 或错读地址。
- type 30/31 接入 `OriginalPageOperationApplier`。合法 payload 以零 page/entity/CRDT 写入返回 applied，保留
  durable inbox 的原始字节幂等、顺序与 server-time cursor；malformed payload 明确 deferred，不吞错。
- NOTE_BUNDLE 对 30/31 执行相同严格 table preflight，事务应用时按原版零写入消费。没有新增数据库迁移、
  评论持久表、虚构 CRDT 或无原版证据的评论 UI。

## 验证

- ArkTS fixture 覆盖 CANVAS/TEXT/ENTITY/REPLY、entity 去重、nullable setter、非零 bool、required ID、
  empty text、unknown union/field、missing changes、NaN point、standalone 零写入和 malformed deferred。
- 新增 `d02-comment-schema-noop.mjs`，覆盖 schema、队头继续 drain、零模型写入与 NOTE_BUNDLE preflight/no-op。
- 全量桌面 replay：`TOTAL=67 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；仅保留仓库既有 warning。未启动模拟器/真机，也未执行设备 Hypium。

## 剩余边界

本阶段按原版 1.0.3 的真实 reducer 行为同时关闭 type 30/31，统一生产路由达到 **25/31**；剩余
**6 类**为 5、6、18、19、20、21，即 Recording 与 Shape/Group。当前不宣称存在可见评论功能；若后续
原版版本提供实际 Comment model/UI consumer，必须以新证据另行实现，不能把 dormant schema 当作 UI 规格。
Goal 继续 active。

# ADR-0034：原版 IMAGE MODIFY_BLOCK 独立寄存器与通用物化

- 状态：Accepted（IMAGE crop/flip 与 common MODIFY；资产 transport 仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0015、ADR-0033

## 原版证据

原版 1.0.3 `td8.java` 的 18-field MODIFY_BLOCK 中，field 12 为 nullable `p2d SetRect`，field 14/15
分别为水平和垂直 flip。`p2d.j()` 返回可空的 `bmb Rect`，所以 wrapper 缺席表示 no-op，wrapper 存在但
Rect 缺席表示 winning clear，Rect 存在才写入四个 float。`gp5.java` 的 IMAGE builder 把三者分别交给
crop、horizontal flip、vertical flip LWW register；`qy0.java` 同时对所有 block 消费 page/origin、rotation、
scale、size、corner、textWrap、enableCaption、positionLocked 与 z-index common register。MODIFY_BLOCK 没有
web URL setter，URL 继续只来自 CREATE。

`u5j.java` 按实际 block 类型校验专属字段：TEXT 的 paper/resize 不能作用于 IMAGE，IMAGE 的 crop/flip 也不能
作用于 TEXT；MATH latex/color 有独立 consumer，不能在尚无 MATH 模型时伪装为已应用。

## 决策

数据库升到 v44，在 `original_block_state` 增加三个独立 IMAGE LWW register：

- crop 保存 x/y/width/height、winner identity 与 present；winner 存在且四值全 NULL 表示显式 clear。
- horizontal/vertical flip 各自保存 boolean value、winner identity 与 present；false 是有效 winning value。
- winner 缺席时分别回落到 v43 已保存的 CREATE crop/flip。

canonical DDL 约束 crop 必须全空或四值完整，flip 必须为 0/1，并禁止非 IMAGE block 携带 IMAGE winner。
v43→v44 迁移为旧行增加缺席 winner；升级库无法用后加列 CHECK 表达的组合约束由读取时的严格 tuple 校验补足，
partial crop 视为 `MODIFY_BLOCK_STATE_DIVERGED`，不得猜测缺值。

`OriginalModifyBlockOperationApplier` 现按 `OriginalBlockType` 与 `PageElementKind` 读取 TEXT/IMAGE：common register
共用同一页面移动、四类 z-order、revision 与 snapshot 物化；TEXT 再消费 paper/resize，IMAGE 再消费 crop/双 flip。
IMAGE 状态一致性同时校验 CREATE-time hash words、文件名、MIME、文件大小、固有尺寸与 URL，避免 MODIFY 在损坏
快照上继续覆盖。live 与 archived 页面共用同一语义，多 block 操作仍由 inbox 外层事务原子提交。

纯 IMAGE 修改会使页面 revision/index state 失效，但不会删除仍有效的 TEXT search item；只有同一操作实际修改了
TEXT block 时才删除 TEXT_BLOCK item。边修边审发现 archived 纯 IMAGE 分支曾因条件写错而使用 `page_id` predicate，
并无条件删除 archived TEXT search；本阶段在最终验证前一并修正为始终按 page sequence identity 更新。

## Deferred 边界

本阶段不实现图片字节网络 transport、PENDING→LOCAL 主动刷新、GIF 动画、caption rich text/UI、ROUND corner
像素半径或 MATH block。CREATE URL 仍不可由 MODIFY 改写。设备 Hypium、原版/Harmony 像素对照及真实远端乱序流
继续留待运行态验收。

## 验证

- `SyncedOperationInbox.test.ets` 增加真实 field 12/14/15 fixture，覆盖 crop set/clear 与 true/false presence。
- `d02-modify-block-image.mjs` 覆盖 v43→v44、迁移回滚、三个独立 winner、CREATE fallback、stale no-op、
  live/archive、跨页、混合层序、多 IMAGE 回滚、类型门禁、partial crop divergence 与 TEXT search 保留。
- 全量 Node/SQLite replay：`TOTAL=43 FAILED=0`。
- clean 后双 HAP 构建结果在本阶段报告记录；未启动模拟器/真机。

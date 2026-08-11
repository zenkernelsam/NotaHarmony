# Phase 83 修复总结：原版 Shape 内 RichText

日期：2026-08-11

基线：`7b35e34 fix(sync): materialize original shape and group state`

范围：原版 Shape RichText、payload type 7–14 复用、数据库 v57、包校验与搜索

## 原版证据

- `n5d` 的 Shape 自己持有 `m4c`；`rbb.k()` 用 `new m4c(null)` 创建空 RichText。
- `m5d.c()` 让 Shape 消费 INSERT_CHAR、INSERT_STRING、REMOVE_CHAR、REMOVE_CHARS、
  REVIVE_CHARS、MODIFY_STYLE、MODIFY_PARAGRAPH_STYLE 与 CLEAR_STYLE，`textField` 指向 Shape
  CREATE operation ID。
- Shape 不消费 type 28 UPDATE_CHECKBOX。type 19 只更新 Shape 寄存器，不能清空独立 RichText。

## 实际修复

- `ShapeElement` 增加向后兼容的可选 `richText`、`characterStyleRuns`、
  `paragraphStyleRuns`；新建原版 Shape 显式为空文本，所有 Shape clone 路径深复制 style runs。
- 数据库升至 v57，character/style 两表的 owner FK 从 `original_block_state` 泛化到
  `original_element_z_index`，迁移保留旧 Text Block 数据并可整体回滚；checkbox 表保持旧边界。
- 文本 target resolver 同时识别 TEXT/SHAPE，并核对具体 Block/Shape owner state，避免仅凭 z-order
  行误认类型。live、deleted page、hidden entity 三条 snapshot 路径均按真实 kind 读写。
- insert、remove/revive 与 style reducer 复用同一字符 CRDT；type 19 重建几何前读取当前 Shape
  snapshot，随后恢复 RichText/runs，修复改颜色、位置或形状时文字被清空的问题。
- UPDATE_CHECKBOX 对 Shape 明确 DEFERRED。包导入按 Unicode code point 校验 Shape style run，搜索
  backfill 与正常保存均索引非空 Shape RichText。
- 边修边审纠正了一个迁移补丁错误：历史 v37 character DDL 继续指向 Block，只有当前 DDL 与 v57
  新表指向 element，确保历史升级语义与新安装语义不互换。

## 验证

- 新增 `d02-shape-rich-text.mjs`：覆盖 v56→v57 保留/故障回滚、Shape character/style、非法 owner、
  cascade、三类文本 reducer、checkbox 拒绝、type 19 保字、隐藏/归档、包校验与搜索。
- 24 个 ArkTS/replay 当前数据库版本守卫同步至 v57；DatabaseHelper 与 NotePackageSpec 测试补充 FK
  及 Shape style-run 断言。
- 全量桌面 replay：`TOTAL=70 FAILED=0`。
- 执行 `hvigor clean` 后，`note@default` 与 `note@ohosTest` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或设备 Hypium，符合本轮约束。

## 未完成边界

Shape RichText 的入站模型、持久化、复制、包校验与搜索已经闭环。Phase 87/ADR-0064 后续通过原版
`itd/z5c/kkf/fu1` 更正了本段旧结论：Android 1.0.3 的静态文字生成器不枚举 Shape，Shape tile 与命中
也只消费几何，因此 Canvas 只绘制 Shape 几何是原版边界，不再把可见 Shape 文字列为待办。outbound
writer 和完整 CRDT export 仍待后续阶段。31/31 生产 payload 路由保持不变，Goal 继续 active。

# Phase 148 修复总结：原版 Math 插入与 CREATE_BLOCK 出站

## 原版对照与问题

- 原版 `y08/z39/fh3/n07` 提供独立 Insert 状态、空 draft editor 和 Done 提交；Harmony 此前只能导入、复制和
  编辑既有 Math，不能从编辑器创建新公式。
- 原版 `g18/s18/u5j` 在 viewport center 创建 Math，使用私有公式引擎测量并约束到 `240x120`，再写 type-22
  `CREATE_BLOCK`。直接把本地 snapshot 加一个 Math 会绕过原版 CRDT identity、LWW reducer 和同步日志。

## 已完成修复

- 工具栏新增 Math 入口，宽屏直达、紧凑模式进入更多菜单；中英文资源均已补齐。
- Insert 打开空 Math editor，Cancel 无副作用；切页取消未提交会话，提交失败保留 overlay 与 draft。
- 新增纯 `OriginalMathInsertPlan`：验证 viewport center、原版 `240x120` 最大测量边界和默认字段，居中生成
  无 identity draft，并为以后接入真实公式测量值保留明确参数。
- 新增 `commitOriginalMathInsert()`：flush 后进入共享 mutex，在单一事务内分配 identity、编码并应用 type-22
  CREATE_BLOCK、写 upload-immediate operation、推进一次 revision、核对 canonical snapshot/search state、
  写 page mutation history companion，失败全部回滚。
- UI 只在 durable 成功后压入 `ADD_ELEMENTS` Undo、安装 canonical Math/order、选择新 Math 并重绘；generation
  改变时不写入其他页面的内存状态。
- 创建快照核对 helper 改为通用原版元素创建语义，继续由 Paste 与 Math Insert 共用同一严格不变量。
- ADR-0125 关闭 Math CREATE writer 边界，并更新 ADR-0124；公式引擎边界没有被虚报关闭。

## 验证与边界

- 专项 replay：
  `localMathInsert=original-insert-state-empty-editor|viewport-center|240x120-engine-bound|type22-create-block|upload-immediate|single-revision|persistent-history|durable-before-ui|selected-result|page-switch-cancel|rollback-keeps-draft`。
- ArkTS fixture 已注册并通过编译，覆盖最大框默认值、未来测量输出和非法中心/尺寸拒绝。
- 全量桌面 replay 为 `TOTAL=134 FAILED=0`；`hvigorw clean` 后严格串行构建 `note@ohosTest` 与
  `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`，只有项目既有 warning。
- 未启动模拟器、虚拟机、真机或 Hypium。Harmony 尚无等价 `GLMathNative`；当前 `240x120` 只是原版最大框，
  不是实际测量。语法级 Invalid/Ok、真实公式排版、尺寸回写和设备像素验收仍待后续。Goal 保持 active。

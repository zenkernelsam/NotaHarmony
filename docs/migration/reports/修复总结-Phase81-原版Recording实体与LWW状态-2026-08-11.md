# Phase 81 修复总结：原版 Recording 实体与 LWW 状态

日期：2026-08-11  
基线：`e0155e0 fix(sync): validate original comment payloads`  
范围：原版 payload type 5/6、录音资产关系、实体可见性、NOTE_BUNDLE、数据库 v55

## 原版证据

本阶段直读 `yn2/ke8/iaj/z0j/ukb/akb/wa0/kaj/tab/gkb/fkb/u5j/v69/fsi`。确认：

- CREATE_RECORDING 的 operation ID 就是 Recording ID；start/end 和 asset metadata 不可变。
- asset metadata 与现有 canonical SHA-512 资产模型同构，不允许凭录音类型另造 hash 或文件协议。
- name、segments、zIndex 是三个独立 register；缺省 name 使用原版 `Id(site=..., timestamp=...)`
  文本，缺省 segments 为 `[start,end]`，缺省 zIndex 为 clientTime。
- MODIFY_RECORDING 可以零字段；三个可选字段分别竞争 LWW，不能合并成一个“大对象 winner”。
- Recording 参加统一 entity delete/undelete，但它是 note-level entity，不是 page element，删除时不应
  搬入 `original_deleted_entity` 页面快照。

## 实际修改

- 数据库升至 v55，新增：
  - `original_recording_state`：不可变录音/资产字段、三个当前值、三个独立 winner；
  - `original_recording_modification`：保留每个 modify identity 的 payload signature，覆盖 stale exact
    retry 与 identity conflict；
  - 所有 uint64 文本列使用 canonical decimal CHECK，note 删除级联两表。
- 新增 `OriginalRecordingOperation.ets`：
  - 严格解码嵌套 RecordingAsset、uint64 起止/zIndex、bounded UTF-8 name、16-byte segment vector；
  - CREATE 校验原版 `start <= end` 和 segment end 上界；MODIFY 对齐原版 outbound 边界约束；
  - CREATE exact retry/conflict、missing target deferred、三个 register stale/site-tie LWW；
  - 复用 canonical asset reference，metadata 到达只建立/合并 PENDING，不虚报音频文件已到达。
- standalone 总路由与 NOTE_BUNDLE 均接入 type 5/6。Bundle preflight 后在既有事务内应用，状态签名
  现在也观察 Recording 变化。
- 扩展 DELETE_ENTITIES：已存在 Recording 只写统一 visibility winner；delete-before-create 仍先保留
  winner。每次 create/delete/undelete 后从可见 Recording 实体重新派生 `has_recordings`。
- ArkTS fixture 新增真实嵌套 FlatBuffer create/modify payload；数据库测试更新 v55 与 DDL 契约。
- 21 个旧 replay 的“当前 DB 版本”机械守卫从 v54 同步到 v55。

## 验证

- 新 replay：`d02-recording-state.mjs` 通过。
- 全量桌面 replay：`TOTAL=68 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或 Hypium，符合本轮约束。

## 未虚报的边界

- 没有录音采集、波形、播放、录音工具 UI、远端音频 byte arrival 或 outbound type 5/6 writer；本阶段
  完成的是原版模型/持久化/入站回放和资产引用。
- 当前自有 `.note` 包是 resolved page snapshot 格式，不承载完整 note-level original CRDT state。只额外
  导出音频会留下孤儿资产，因此 Recording 包格式扩展必须与模型序列化、导入 ID 重映射和资产校验一起做。
- 统一生产路由达到 **27/31**；剩余 4 类为 type 18/19/20/21，即 Shape/Group create/modify。

## 后续

下一阶段直接处理 Shape/Group 四类，不为重新追求“审全”停工。完成静态生产路由后仍需设备侧集中验收
录音文件到达/播放、输入、渲染、数据库真实升级、WebDAV 和私有同步服务。

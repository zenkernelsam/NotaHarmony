# Phase 106 修复总结：原版本地 CREATE_INK 出站与撤销

## 原版证据

- 原版 `haa` 将 CREATE_INK 固定为 payload type 15；`dm2/ys2.O()` 对应 20-field FlatBuffer，
  包含 page SeqId、origin/transform、tool/style/tape、RGBA、width、中心/轮廓/填充路径、styleMap、
  zIndex、audioDuration、nib 与 Ink effects。
- `kt1.d()` 在 touch-down 经 `u5j.g()` 建立 transient Ink；Ink 实体身份就是 CREATE_INK 的
  `(timestamp, siteId)`，不是随机字符串。目标页引用 CREATE_PAGE 产生的稳定 `cxc` SeqId。
- `faj/u5j/ldj.M2()` 是实际路径 writer 链；live Ink 使用 version 0、BITS_32 坐标，并从 attributed
  MOVE 开始携带 width/force/altitude/azimuth。Pencil 的稳定散点 seed 保存在 `yyd` styleMap。
- 原版 DELETE_ENTITIES 的 entityDeletes/entityUndeletes 以 operation identity 删除和恢复同一实体。

## 已完成修复

- 新增原版中心路径与 CREATE_INK writer：写入 BITS_32 cubic center path、原版工具/样式映射、RGBA、
  width、Tape/effects，并为 Pencil 写入一项 styleMap，使落笔预览与跨端 reducer 重放使用同一 seed。
- 页面加载/切页时只为严格对齐页预留 operation identity：page identity 必须 live，Harmony snapshot
  与 `original_element_z_index` 的 visible membership、uint64 z-order 必须完全相同，且页面未被 v59
  authoring guard 阻断。touch-down 同步消费 reservation，stroke 从一开始就是 canonical `op:*` ID。
- reservation、CREATE_INK reducer、原版 outbound 行和 Harmony history companion 全部使用共享
  `editorPersistenceMutex`；持久化事务会再次检查 page SeqId/顺序。defer、顺序变化、append 或注入故障
  均整体回滚，不留下半个原版 Ink、双 revision 或假的 canonical ID。
- 普通本地 mutation 不再被 CREATE_INK reducer 再次全量覆盖；原版 reducer 负责插入 Ink 与推进一次
  content revision，随后只精确校正 materialized row/revision/order、搜索状态，并追加本地 history companion。
- ADD_STROKE 单步与 coalesced group 的 Undo/Redo 均已接入原版 DELETE_ENTITIES：Undo 发 entityDeletes，
  Redo 发 entityUndeletes，始终复用同一 Ink identity、z-order 与 archived payload；本地 Undo 栈仍由带
  history metadata 的 Harmony companion 恢复。
- `PersistentHistory` 将 `ORIGINAL_CREATE_INK` 视为透明 outbound companion，不再把它误判成 legacy
  barrier。DELETE_ENTITIES writer 同时支持 entity delete/undelete，并拒绝同一 identity 同批冲突。
- 新增数据库 v59 `original_local_ink_authoring_guard`。一旦页面发生尚未迁移的 transform、erase、文本、
  shape、image、math 等 Harmony-only 内容 mutation，该页跨重启保持保守回退，不能在旧状态上继续发送
  看似正确的 CREATE_INK。
- 把 snapshot JSON codec 从 `StrokePersistence` 提取到独立模块，解除 reducer 与 persistence 的反向依赖，
  避免生产接线后形成模块初始化环。
- 边修边审发现并修复快速切页竞态：旧页 reservation Promise 只在相同 page-load generation/pageId
  内共享；新页等待旧事务收尾后为自己重试，既不会误装旧 identity，也不会无声失去原版 CREATE_INK 出站资格。

## 验证

- 新增 `OriginalCreateInkPayloadEncoder.test.ets`：覆盖 dm2/path round-trip、Pencil styleMap seed、严格
  operation ID 解析和 entity delete/undelete vectors。clean `note@ohosTest` ArkTS/HAP 编译通过。
- 专项 replay 输出：
  `localCreateInk=bits32-canonical-original-visibility-history-guard-rollback`。
- 全量桌面 replay：`TOTAL=92 FAILED=0`。
- `hvigor clean` 为 `BUILD SUCCESSFUL`；随后严格串行构建 `note@ohosTest` 与 `note@default`，
  两套 HAP 均为 `BUILD SUCCESSFUL`，且 unsigned HAP 产物均已落盘。

## 仍待后续

- 本阶段没有虚报本地 ADD_PATH_ELEMENTS streaming、MODIFY_INK transform/style/partial erase、whole eraser
  多实体批处理、原版 text/shape/image/math authoring 或私有 transport/ACK 已完成；这些仍需继续按原版推进。
- 未启动模拟器、虚拟机或真机，也未执行设备 Hypium。真实触控延迟、Pencil 纹理、录音联动 Ink、跨端上传/
  下载及 Undo/Redo 仍需明早设备集中验收。Goal 保持 active。

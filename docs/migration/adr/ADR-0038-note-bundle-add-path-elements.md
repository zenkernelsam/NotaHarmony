# ADR-0038：NOTE_BUNDLE ADD_PATH_ELEMENTS 确定性回放与严格幂等

- 状态：Accepted（最终可见 Ink 的 actual/estimated 路径追加）
- 日期：2026-08-11
- 关联：D-02、ADR-0012、ADR-0025、ADR-0026、ADR-0037

## 原版证据

原版 payload type 16 对应 `gd`/`haa.ADD_PATH_ELEMENTS`，child table 保存目标 Ink operation identity、actual
`encodedCenterPathElements` 与 estimated `encodedCenterPathEstimatedElements`。它与实时 operation 使用同一 payload table；
actual 是按 ADD operation identity 保存的追加集合，estimated 是 Ink 上独立的 LWW register。原版允许 actual-only、
estimated-only 与 actual+estimated；较新的 actual-only 会以显式空值清除旧预测尾段。

Harmony 实时 applier 已按 base path + identity 排序的 actual appends + winning estimated 尾段全量重建，并对 Pencil 使用
CREATE style-map seed/reference point 确定性重建 splats。NOTE_BUNDLE 必须复用这一实现，不能按 vector 到达顺序拼接坐标，
也不能把 estimated 写进持久 actual path。

## 决策

`OriginalAddPathElementsOperationApplier` 增加 table-level `preflightTable/applyTable`，与实时 `apply()` 共用
`applyPayload()`。预检在页面身份写入前完成 child table、actual/estimated path 编码和资源上限校验；应用仍复用现有 target、
base state、stroke geometry、Pencil splat、bounds、snapshot、revision 与搜索失效逻辑。

NOTE_BUNDLE 内容 orchestrator 按 operation vector 顺序处理 CREATE_INK 与 ADD_PATH_ELEMENTS。整个页面 bootstrap 和全部内容
仍位于 ADR-0037 建立的同一事务；ADD target 缺失、几何分歧、预算超限或第二条内容失败都会回滚页面身份及之前内容。
bundle 的 `applied` 结果不能只看 element count，因为 ADD 不创建元素；现同时比较 live/archive 页面 content revision 总量。

重复 ADD 的判定提前到目标页解析前：

- actual append 已存在时字节必须相同，estimated winner 必须等于或新于该 operation；
- estimated winner 等于 operation 时 winning bytes 必须与输入一致；
- 同 identity 只出现 actual 或只出现 estimated 的不可能状态视为部分持久化并报错；
- estimated-only 被较新 winner 覆盖时为幂等 no-op；actual 尚未存在但有较新 estimated winner 时仍应追加 actual，不能误判 stale；
- 页面仍可访问时，幂等路径继续按当前 appends/estimated 重建并核对 snapshot 几何；元素后来删除或归档导致 target 不可访问时，
  已完整保存的 operation 才可直接 no-op。

相同 identity 的 actual/estimated 冲突字节与部分状态都会抛错并触发 bundle 事务回滚，不用主键异常充当重复判断。

## 验证

- `SyncedOperationInbox.test.ets`：真实 NOTE_BUNDLE 同时包含 CREATE_PAGE、CREATE_INK 与 ADD_PATH_ELEMENTS child table，
  验证 type 16 target、path bytes 与 table preflight。
- `d02-note-bundle-add-path.mjs`：actual+estimated、actual-only clear、estimated LWW、旧 winner no-op、actual/estimated 重复
  幂等、同 identity 冲突、部分状态、故障回滚与 revision marker。
- 全量 D-02 Node/SQLite replay：`TOTAL=47 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`；未启动设备或执行 Hypium。

## Deferred 边界

本阶段不关闭 NOTE_BUNDLE MODIFY_INK、entity delete/undelete、归档页首次内容物化、Block/Text/RichText、Tape/effects、
PDF/note background fallback、认证 transport 或服务端 note/site 创建。operation vector 若把 ADD 放在其目标 CREATE 之前，
当前会整批 deferred；没有原版排序证据前不擅自重排依赖操作。

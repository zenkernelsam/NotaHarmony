# ADR-0026：原版 estimated center-path 独立 LWW 与完整路径物化

- 状态：Accepted
- 日期：2026-08-11
- 关联：D-02、ADR-0005、ADR-0024、ADR-0025、数据库 v42

## 原版证据

`ADD_PATH_ELEMENTS=16` 的 `gd` 同时允许 actual field 1 和 estimated field 2。原版 `q06.c()` 将 actual 解码为带追加 op identity
的 `op7` 并插入有序结构；estimated 则无条件以当前 ADD identity 写入 `centerPathEstimatedRegister`。`fh3(case 14)` 在 field 2
缺席时返回空列表，因此较新的 actual-only ADD 会清除旧 estimated，而不是让预测尾段永久残留。

该 register 进入 `d16.h`，`s06.R()` 读取其 winner，`s06.Q()` 严格拼接 `Y() + e + R()`。最终 bounds、普通 Ink renderer 和
`p16.t()` Pencil renderer 都消费 `Q()`。所以 estimated 是持久 CRDT 模型中的可替换预测尾段，不能丢弃，也不能写入 actual
append 序列。

## 决策

数据库升至 v42，在 `original_ink_state` 增加 estimated 原始 path-elements BLOB、winner timestamp/site 和 present 位。CREATE
初始化为空且无 winner；v41→v42 迁移同样使用该无损初始状态。

ADD 应用先以 base/replacement + 全部有序 actual rows + 当前 estimated winner 重建并校验 snapshot。actual field 若存在仍独立插入
有序 append 表；每条 ADD 的 estimated 候选是 field 2 内容，缺席则为空。只有严格较新的 op identity 更新 estimated register，较旧
op 的 actual 仍可进入 CRDT，但不得覆盖较新的预测 winner。estimated-only stale op 是零修改，不推进 revision。

候选 geometry 始终按 actual 后接 estimated 的顺序重建。Pencil splats、bounds 和 Pen variable-width 属性检查都覆盖 estimated
尾段；MODIFY_INK 重建也读取当前 estimated value，避免 width/style-map/center-path 修改时丢掉预测尾段。所有状态、snapshot、
revision 与搜索失效仍处于 synced inbox 的同一事务。

## 验证与边界

- `d02-add-path-elements.mjs` 保留真实 `gd/qo5` field 2 FlatBuffer fixture。
- 新增 `d02-add-path-estimated.mjs`，覆盖 v41→v42、estimated-only、actual 乱序、LWW stale、actual-only clear、snapshot 分歧、
  应用与迁移回滚，以及 MODIFY consumer。
- 全量 35 个 D-02 replay 通过；`note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。
- 设备 Hypium 与真实远端预测流未执行；包含 move 的 multi-component、Tape/effects 和 NOTE_BUNDLE 内容 replay 仍未完成，D-02
  不关闭。

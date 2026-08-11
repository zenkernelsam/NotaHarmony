# Phase 121 修复总结：原版 Block 与 Shape 锁定/解锁闭环

## 原版证据与纠错

- 直读原版 `dsc/ux9/dhb/u5j/a1j/td8/cz3/xsc`，确认 Lock/Unlock 是两项真实选区命令：
  Block 写 type-23 field 17，Shape 写 type-19 field 14，false 也必须保持字段 presence。
- 原版单实体可切换 Block 或 Shape；绘制/Group 选区分支只接受纯 Shape，并在全部 Shape 已锁时
  显示 Unlock。Harmony 因没有独立 tap selection state，将单个实体作为等价直接选择路径。
- 纠正 ADR-0016 的早期假设：锁定对象必须仍能进入选区，否则用户永远无法触发 Unlock；锁定保护
  应位于 transform/edit/eraser consumer，而不是 selection discovery。

## 已完成修复

- type-19/type-23 encoder 新增 position-lock writer；true/false 均可 round-trip，空目标、重复目标和
  非法 Shape boolean 继续严格拒绝。
- `SelectionOverlay/NoteCanvasView` 新增 Lock/Unlock 菜单、原版门禁、混合锁态判断与单个
  `TRANSFORM_ELEMENTS` Undo action。锁定后不清空选区，可立即 Unlock。
- `SelectionTool` 保留 locked Shape/Text/Image/Math 的矩形、套索及 Group 选择；现有 Block
  transform/eraser/edit 门禁继续生效。边修边审发现并补齐 locked Shape 仍可移动、缩放及被整对象
  橡皮删除的遗漏。
- 严格 snapshot classifier 只接受 `positionLocked` 单字段变化，并按目标值拆 Shape/Block batch。
  Shape state 与 Block CREATE/winner state 都核验 before-lock；旧 Shape resolved JSON 缺字段时按原版
  FlatBuffer 默认 false，非法非 boolean 仍拒绝。
- 普通保存及 grouped Undo/Redo 共用一个事务、一个 page mutation batch、一次 revision、完整原版
  envelope、生产 reducer、upload-immediate journal、snapshot reconciliation 与 history companion。

## 测试与验证

- ArkTS fixture 覆盖 Shape/Block true 与 explicit false、混合 classifier、正反向 source-state、无关几何
  拒绝、locked 四类实体可选、locked Shape 不变换且不被对象橡皮命中；`note@ohosTest` 增量编译成功。
- 新增 `d02-local-position-lock.mjs`，并修订 5 个仍断言“locked 不可选”的历史 replay。专项输出为
  `localPositionLock=original-type19-type23-select-unlock-source-preflight-single-revision-undo-redo-rollback`。
- 最终全量 replay 为 `TOTAL=107 FAILED=0`；`git diff --check` 通过；执行 `hvigor clean` 后严格串行
  构建 `note@ohosTest` 与 `note@default`，均为 `BUILD SUCCESSFUL`。未启动模拟器、虚拟机、真机或
  Hypium。

## 仍待后续

- 本地 Group authoring、其余 Shape definition/tool/effects register、完整原版 CRDT 包、私有认证
  upload/ACK 与设备交互验收继续后续阶段，Goal 保持 active。

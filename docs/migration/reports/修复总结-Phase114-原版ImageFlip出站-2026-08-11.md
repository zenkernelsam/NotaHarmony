# Phase 114 修复总结：原版 Image Flip 出站

## 原版证据与边修边审更正

- 原版 `dsc/dhb/tk4` 表明水平/垂直 Flip 进入 `mub case 5`，不是通用选区位置变换。
- 对原版 APK 以 JADX fallback 复核 `mub.invokeSuspend` 后确认：命令逐个过滤 `hp5` Image，逐张读取并
  取反 H/V 状态，每张 Image 生成一条 singleton `u5j.o` 操作，最后把操作列表一次提交。
- 同一分支在 Image 已裁剪时，按 intrinsic width/height 镜像 crop origin，并把 crop setter 与 flip
  寄存器写在同一条 type-23 `MODIFY_BLOCK`。因此“只切布尔值、不改 crop”的初始计划也被继续更正。
- `u5j.n/td8/rl2` 共同确认 field 12/14/15 分别是 crop、水平 flip、垂直 flip，`false` 必须保留
  field presence，非 Image Block 明确拒绝 Flip。

## 已完成修复

- 新增 `OriginalModifyBlockPayloadEncoder`：支持 1..10,000 个去重 Block identity、可选 crop setter、
  H/V field presence 与显式 false；无目标、重复目标、无更新和非法 crop 均拒绝。
- 新增严格 snapshot classifier。identity/order 必须不变；所有变化只能来自 canonical Image，单次动作
  只允许同一轴；每张图片可以得到不同最终布尔值，并严格验证原版 crop reflection 之外没有夹带字段。
- 普通保存与 grouped Undo/Redo 均优先走原版 Image Flip writer。生产路径逐 Image 分配 operation
  identity、生成完整 `uq9` type 23、调用既有 LWW reducer、写 upload-immediate journal；共享
  `OriginalPageMutationBatch` 只推进一次页面 revision，任一 reducer/append/reconcile 故障整事务回滚。
- 新增 `OpType.ORIGINAL_MODIFY_BLOCK`；修复 Phase 111 遗漏，把 `ORIGINAL_MODIFY_POSITIONS` 和新
  `ORIGINAL_MODIFY_BLOCK` 都设为 PersistentHistory 透明 companion，避免它们被误当 legacy barrier。
- `NoteCanvasView.flipSelected()` 不再制造负 determinant 反射矩阵，也不修改 Stroke/Shape/Text/Math。
  现在仅处理未锁定的纯 Image 直选，逐张 toggle H/V；已有 crop 以 float32 原版顺序镜像，transform、
  bounds、rotation 保持不变。菜单只在该条件成立时显示 Flip，handler 内再次校验。
- 历史继续复用 Image before/after 快照；Undo/Redo 反向状态再次被 classifier 识别并写出原版寄存器。
  早期 T-022/T-036 与 Phase 85 中把 Flip 视为通用矩阵变换的描述已加 Phase 114 更正。

## 验证

- 新增 `d02-local-image-flip-outbound.mjs`，专项输出：
  `localImageFlip=singleton-modify-block-per-image-crop-reflection-batched-revision-rollback`。
- replay 覆盖原版命令/字段/type gate、逐图混合初值、crop reflection、singleton journal、单次 revision、
  故障全回滚、UI Image-only gate、旧 position companion 透明修复。
- 新增 ArkTS encoder 与 classifier tests，覆盖 true/false presence、H/V、多图、crop、混轴/非 Image/
  夹带字段拒绝，以及 Undo/Redo 正反向寄存器；fixture 已注册进 `note/src/test/List.test.ets`。
- 全量桌面 replay：`TOTAL=100 FAILED=0`；`git diff --check` 通过。
- 执行 `hvigor clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，均为
  `BUILD SUCCESSFUL`；只有项目既有 ArkTS/deprecation warning 与未配置签名提示。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 仍待后续

- 真机需集中验证未裁剪/裁剪 Image、混合初始 flip 状态、连续 H/V、Undo/Redo、重启、远端回放和
  跨端像素一致性；本阶段不虚报设备视觉验收。
- crop 编辑 UI、其他 common/type-specific `MODIFY_BLOCK` 本地 writer、逐层移动、Group authoring、
  私有认证 upload/ACK、格式闭环和集中设备验收继续后续阶段。Goal 保持 active。

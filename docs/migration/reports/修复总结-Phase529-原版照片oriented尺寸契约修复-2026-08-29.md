# 修复总结 — Phase 529 原版照片 oriented 尺寸契约修复

日期：2026-08-29

## 问题

继续复审照片/图片链发现：照片 ingress 同时返回 encoded 与 oriented 尺寸，但
`NoteCanvasView` 生成 IMAGE persistence plan 时使用了 encoded 轴作为 intrinsic。
对于保留原始字节的 EXIF 90°/270° 小图，这会把原版 `vuh.b()` 返回的对外尺寸写反，
导致 block fit、CREATE_BLOCK size 和实际方向化显示不一致。

同时，normalizer 的采样调用仍使用变量 `oriented`，未明确表达原版“encoded 轴采样、
旋转后 oriented 目标”的两步契约。

## 修复

- `normalizeOriginalImageBytes()` 现在严格以 encoded header 轴调用 downscale planner；
  再将计划尺寸按 EXIF 转换为 `targetOriented`，旋转后缩放并校验最终轴；
- 重写后的无 EXIF WebP 将最终物理轴同时作为 encoded/oriented 输出轴；
- `normalizedOriginalImagePersistencePlan()` 与 `NoteCanvasView` 统一使用
  `orientedWidth/orientedHeight` 作为 IMAGE intrinsic；
- 更新旧四分之一旋转 Replay，并新增 oriented 尺寸专项 Replay、ADR、evidence 与 fixture。
- 修正图片 renderer 的坐标桥接：持久化 intrinsic/crop 使用 oriented 域，raw bitmap 由
  encoded 宽高矩阵映射到 oriented 域后再执行用户翻转、crop 与 block fit；补充四个 quarter-turn
  和 EXIF mirror 的纯数学 fixture，避免 90°/270° 小图出现比例或裁剪错位。

## 证据与验证

- Phase 529 oriented 尺寸专项：`15/15`；
- Phase 529 oriented/renderer 专项：`19/19`；本阶段受影响的 13 个图片/照片/资产 Replay
  共 `149/149` 项通过；
- ArkTS：renderer、crop geometry、normalizer、persistence、caller 与两组 fixture 无新增错误；
  其余提示为既有 warning/information（包括 `ImagePacker.packing` 弃用提示）。
- 全量 Desktop Replay：`REPLAY_FILES=424 PASSED=424 FAILED_FILES=0`（32.013 秒）；
- clean：`BUILD SUCCESSFUL in 1 s 593 ms`（外部计时 2.589 秒）；
  `note@ohosTest`：`BUILD SUCCESSFUL in 7 s 869 ms`（外部计时 9.002 秒）；
  `note@default`：`BUILD SUCCESSFUL in 54 s 459 ms`（外部计时 55.678 秒）。
- unsigned HAP：`note-ohosTest-unsigned.hap` 6,491,162 bytes，SHA-256
  `BA0113ED0E0D3B4E3FE38F00994C69E611F44B0EE794CA674A571ECAABC0A156`；
  `note-default-unsigned.hap` 15,633,210 bytes，SHA-256
  `7908C77754718E6A7C7D50B336CCAF05B558D48D36B78884CB6723E2CF38600F`。
- 本次生成的 `.hvigor`、`note/build`、`note/.cxx` 已完整移入
  `NotaHarmony-quarantine-2026-08-29/repo-generated/phase529-final`，未删除；
- 未启动模拟器、虚拟机、真机或 Hypium，`T-042` 继续保持整个 Goal 的最后任务。

# Phase 615 — DUPLICATE 无门槛；>=2 门槛属 GROUP（dhb case 序即 dsc ordinal）

## 原版证据

- `dsc.java:31-43`：菜单枚举序 STYLE=0, COPY=1, CUT=2,
  **DUPLICATE=3**, **GROUP=4**, UNGROUP=5。
- `dhb.java:17630-17636`：case2(CUT)/case3(DUPLICATE) 均派发
  `vsc` 协程，仅构造尾参（`vsc.I`）不同。
- `vsc.java:45-80`：`I==0` → `lg2.d`（cut）；`I==1` → `lg2.b`。
- `lg2.java:171-191`：`b()` = `g()` 构建负载 → `fvb.a()` 清选区
  → `e()` 就地应用负载（粘贴即重选），对任意 `ktc` 生效——
  `itc` 单元素、`gtc` 单组均可 DUPLICATE，**无数量门槛**。
- `dhb.java:17638-17654`：case4 = GROUP（dsc=4）：仅 `ftc`
  多选壳且 `A1=T1(ftc.q)+组id size>=2` 才派发 `kk9` 建组协程
  并 `fvb.a()` 清选区。
- `gtc.java:90-93`：`gtc.f()`=空集，`A1` = 未入组散件 + 组 id。

## 纠错说明

初版误把 `dhb` case4 当 DUPLICATE——case 号即 `dsc` ordinal，
case4=GROUP、case3=DUPLICATE。`A1>=2` 门槛属 GROUP 建组，
Harmony `selectionCanGroup = authoringMembers >= 2` 本就已等价
（`resolveOriginalGroupAuthoringMembers` 即 `T1(ftc.q)+组id`）。
DUPLICATE 经 `vsc` → `lg2.b` = 复制+就地粘贴复合，无门槛——
Harmony 旧实现（无条件 push + 无入口门槛）本就是正确对齐。

## 修复

撤销初版误加门槛，恢复到正确对齐状态：

- `NoteCanvasView.ets`：移除 `@State selectionCanDuplicate`、
  `updateSelectionOverlay` 中的门槛计算与 `duplicateSelected`
  入口门槛。
- `SelectionOverlay.ets`：移除 `@Prop canDuplicate`，
  DUPLICATE 恢复无条件 push。

## 验证

- 更新 replay `d02-original-duplicate-gate.mjs`：12/12 绿
  （DUPLICATE 无条件、duplicateSelected 无门槛、GROUP 门槛
  保持、粘贴后重选）。
- 全量 desktop replay 套件：505/505 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

初版 `Phase 615: DUPLICATE requires >=2 top-level items (dhb case4)`
（解码有误，已由后续纠正提交撤销门槛）。

# ADR-1351 窄屏撤销/重做引导气泡 `PHONE_UNDO_REDO`

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1415
- 接续：Phase 1327 群（onboarding 引导链 pq9/hq9 → Harmony
  `OnboardingTooltipStore`）、ADR-0652/ADR-1327/ADR-0644（同类
  fail-closed 条目）
- 证据：`docs/migration/evidence/phase-1415-phone-undo-redo.md`

## 背景

原版 onboarding 链在 undo 可用位点（`x90` gl8Var5）按窗口宽度分流
两枚气泡——`dhb` default 分支：

```java
boolean zD = jh2.d(nc6Var2);   // 窗口宽度 <600dp → true
wv9.b(zD ? t0c.M : t0c.L, zD ? 2 : 3, …);
```

- `t0c.M` = `PHONE_UNDO_REDO`（窄屏/手机布局，文案 "Press to undo,
  long press to redo"，槽位 2 = 锚点下方居中）；
- `t0c.L` = `FIRST_UNDO_REDO`（宽屏，双指/三指手势文案，槽位 3 =
  锚点左侧）。

Harmony 此前仅实现 `FIRST_UNDO_REDO`（`Placement.Left`），窄屏缺失
`t0c.M` 分支——窄屏用户看到宽屏手势文案，且位置错位。

## 决策

1. `OnboardingTooltipKind` 增补 `PHONE_UNDO_REDO` 并进
   `isOnboardingTooltipKind` 容错表；seen 集语义与 hq9 相同
   （两枚独立持久化，互不抑制）。
2. `EditorToolbar` 复用既有 `compact = width<600` 断点（与 `jh2.d`
   等价）在 `canUndo` 站点按 `compact` 选 kind；弹出时把选中 kind
   锁入 `@State undoRedoTipKind`，文案/位置/ dismissed 记录同 kind
   闭环，避免宽度跨阈值途中串味。
3. 位置映射：槽位 2 → `Placement.Bottom`（窄屏，锚点下方居中、
   越界上翻）；槽位 3 → `Placement.Left`（宽屏，既有行为不变）。
   `mask:false`/`autoCancel:false` 维持非模态。
4. 同一站点两枚互斥：`tipSeen(undoTipKind)` 只对当前应展示的那枚
   判定；`dismissOnboardingTip` 同时覆盖两种 kind 的隐藏分支。

## 未移植的同类条目（fail-closed 维持）

| `t0c` 种类 | 原因 |
|------------|------|
| `FIRST_TRANSCRIPT` | Learn AI 转写后端（ADR-0652 群） |
| `FIRST_RAINBOW_EFFECT` | Google Ink rainbow brush pack（ADR-1327 群） |
| `FIRST_RULER_ENABLED` / `FIRST_ANGLE_MEASURE_MODE` | 原版自身隐藏 + 无直尺表面（ADR-0644 群） |
| `SAVE_AS_TEMPLATE` | 无 save-as-template 宿主表面 |

## 验证

- Replay `d02-original-phone-undo-redo-tip.mjs`：13/13（原版枚举/
  分流/槽位/文案 + Harmony 枚举/断点/kind 分流/位置/双语）。
- 既有 `d02-original-onboarding-tooltips.mjs` 仍为绿（新增枚举为
  加法，不破计数断言）。

# Phase 1415 证据：窄屏撤销/重做引导气泡 `PHONE_UNDO_REDO`

- 版本证据基线：`decompiled_1.4.2`
- 接续 Phase 1414：onboarding 引导链最后一枚可移植条目；其余缺失种
  类（transcript/rainbow/ruler×2/save-as-template）均为 fail-closed 表面。

## 1. 枚举与持久化（t0c / wv9 链 / 已有 hq9 对等）

| 原版 | 语义 | 证据 |
|------|------|------|
| `t0c` 枚举 | 17 种引导气泡；`"PHONE_UNDO_REDO", 9` 与 `"FIRST_UNDO_REDO", 8` 并存 | `t0c.java` |
| `wv9.b(t0c, slot, ...)` | seen 集持久化 + 槽位 int 经 `nyi.b` → `tyi(slot,offsetPx)` | `wv9.java`、`nyi.java` |
| `hq9` | SharedPreferences `onboardingTooltipSeen` Set\<String\>，`pq9.valueOf` 容错读回 | `hq9.java` |

## 2. 触发分流（dhb default / jh2.d）

| 原版 | 语义 | 证据 |
|------|------|------|
| `dhb` default | `boolean zD = jh2.d(nc6Var2); … wv9.b(zD ? t0c.M : t0c.L, zD ? 2 : 3, …)`；undo 可用时窄屏出 M、宽屏出 L | `dhb.java` |
| `jh2.d(qh2)` | `z4kVar.a(600)` 判定：窗口宽度 <600dp → `return true`（compact/phone 布局） | `jh2.java` |
| `x90` gl8Var5 | undo 可用位点（`performHistory` 旁的 onboarding 钩子）；同一站点在宽/窄屏分流两枚气泡 | `x90.java` |

## 3. 弹出位置（tyi 槽位语义）

| 原版 | 语义 | 证据 |
|------|------|------|
| `tyi` 构造 | `this.F; … i == 3 … return b(j2…)`；`b()` 把锚点左侧定位（`b(j2,…)` = left-of-anchor） | `tyi.java` |
| `tyi` 槽位 2 | 2 = 锚点下方居中（越界时上翻），offsetPx 纵向偏移 | `tyi.java` |

→ Harmony 映射：槽位 3 = `Placement.Left`（既有 FIRST_UNDO_REDO 已对齐）；
槽位 2 = `Placement.Bottom`。

## 4. 文案（ad case9/8）

| 原版 | 语义 | 证据 |
|------|------|------|
| `ad` 分发 | case9 → `data_onboarding__phone_undo_redo_tooltip_text`；case8 → `data_onboarding__first_undo_redo_tooltip_text` | `ad.java` |
| 文案 | `<string name="data_onboarding__phone_undo_redo_tooltip_text">Press to undo, long press to redo</string>` | `strings.xml` |

> 1.4.2 文案为 "Press to undo, long press to redo"（撤销/重做按钮在窄屏
> 直接可点）；与宽屏双指/三指手势文案并存于同一 `ad` 分发。

## 5. Harmony 实现映射

| 原版 | Harmony | 状态 |
|------|---------|------|
| `jh2.d` 宽<600 | `onAreaChange` 已有 `this.compact = (newArea.width as number) < 600` | ✅ 断点等价 |
| `zD ? t0c.M : t0c.L` | `const undoTipKind = this.compact ? PHONE_UNDO_REDO : FIRST_UNDO_REDO`（canUndo 且未见时） | ✅ |
| 槽位 2/3 | `placement: undoRedoTipKind === PHONE_UNDO_REDO ? Placement.Bottom : Placement.Left` | ✅ |
| case9 文案 | `tipText` 按 `undoRedoTipKind` 分流 `phone_undo_redo`/`first_undo_redo` | ✅ |
| hq9 seen 集 | `OnboardingTooltipStore.markSeen` + `isOnboardingTooltipKind` 容错表新增 `PHONE_UNDO_REDO` | ✅ |
| 非模态 | `mask:false`/`autoCancel:false` 维持 | ✅ |

## 6. 同步 fail-closed 面

| 原版种类 | Harmony 状态 |
|----------|--------------|
| `FIRST_TRANSCRIPT` | Learn AI 转写后端（ADR-0652 群）→ fail-closed |
| `FIRST_RAINBOW_EFFECT` | Google Ink rainbow brush pack（ADR-1327 群）→ fail-closed |
| `FIRST_RULER_ENABLED` / `FIRST_ANGLE_MEASURE_MODE` | 原版自身隐藏 + 无直尺/量角表面（ADR-0644 群）→ fail-closed |
| `SAVE_AS_TEMPLATE` | 无 save-as-template 宿主表面 → fail-closed |

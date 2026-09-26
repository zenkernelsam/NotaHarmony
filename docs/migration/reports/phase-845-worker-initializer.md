# Phase 845 — Worker + Initializer 清单闭合

## 范围

全包 `*Worker`（15 类）与 `*Initializer`（6 类）盘点，
约束/继承结构核验。

## 原版发现

### Worker×15

- 12 直系 `CoroutineWorker`；`NoteAssetDownload`/`Upload` 经
  `NoteAssetTransferWorker` 共享基类；`UnresolvableWorker`
  为 DI 失败占位（普通 Worker，返回 success 桩）。
- 域分布：maintenance(12h)、demo 重置、gallery outbox、
  hwr 语言包、export 清扫、library 上传、ops 拉取、
  asset 管线×3、template×2、sticker×2。

### Initializer×6

- DataStore 域：user/theme/editor-settings/haptic；
- androidx.startup 域：AppStartup/Logging（836 已记）。

## Harmony 侧

- 无 `workScheduler`/`transientTask`；后台仅 834 连续任务；
- 初始化对应 `ThemeStore.init()` + DataStore 惰性装载。

## 验证

- Replay `d02-worker-initializer.mjs`：**13/13**（15 类清单
  全命中、CoroutineWorker 继承结构、6 initializer 命名命中、
  Harmony 断言两项）。
- ADR-0789。**调度/初始化面闭合。**

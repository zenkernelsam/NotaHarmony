# Phase 832 — MainActivity dispatch/lifecycle 体语义

## 范围

`MainActivity.java`（675 行）15 个 override 的方法体语义审计，
补 826（attrs）/827（key/sensor）未覆盖面。

## 原版发现

### dispatchKeyEvent 细节

- `qdn.a` 文本域短路：输入域内按键不进应用级和弦表；
- `vla.b` 和弦→action 解码后经 `bma.a.f` 发射编辑管道；
- **New Window 和弦门控 `oim.a`** = `smallestScreenWidthDp
  >= 600`——平板专属，手机丢弃并记日志。

### 其余方法体

- `dispatchTouchEvent`：fzm.d 埋点 + `nxb` SecurityException
  守卫（遮挡窗口触摸 bug 规避）；
- `dispatchGenericMotionEvent`：fzm.b stylus 埋点；
- `onActivityResult(1123)`：Play 应用内更新失败 → "AppUpdateFailed"
  埋点 + `p()` **不可取消**强制更新对话框（6 字符串族：
  required_title/message + action_{update,exit,later,restart}）；
- `onSaveInstanceState`：持久化 `showWhenLockedPolicy`；
- `onStart`→`r()`：`bub.a()` 策略动态重算
  `setShowWhenLocked/setTurnScreenOn`；
- `onTopResumedActivityChanged`：多窗置顶重跑配置；
- `onUserInteraction`：`ow3.a` 交互打点。

## Harmony 侧

- force-update 阻断流：无应用内更新 runtime——**登记不移植**；
- sw600 和弦门控：随 827 缺口一并登记；
- showWhenLockedPolicy 持久化：826 平台差已登记；
- 触摸守卫/埋点/多窗回调：平台特有，归档。

## 验证

- 新 Replay `d02-mainactivity-semantics.mjs`：**15/15**（15 个
  override 齐在、短路/门控/发射链、三路埋点、1123 更新流、
  6 字符串族、锁屏持久化、多窗回调、交互打点）。
- ADR-0776。**MainActivity 行为面全部归因完毕。**

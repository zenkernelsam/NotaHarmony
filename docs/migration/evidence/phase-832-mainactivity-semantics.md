# Phase 832 — MainActivity dispatch/lifecycle 体语义

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/app/MainActivity.java`（675 行，全 override 清单）

## 一、Override 清单

`dispatchGenericMotionEvent` / `dispatchKeyEvent` / `dispatchTouchEvent` /
`onActivityResult` / `onConfigurationChanged` / `onCreate` / `onDestroy` /
`onNewIntent` / `onPause` / `onProvideKeyboardShortcuts` / `onResume` /
`onSaveInstanceState` / `onStart` / `onTopResumedActivityChanged` /
`onUserInteraction`（15 个；key/sensor 面已 827 登记，本相位补其余）。

## 二、dispatchKeyEvent 补充语义（827 之外的细节）

```java
if (!qdn.a(keyEvent) || !l().d()) {       // qdn.a=文本域归属短路
    if (!vla.a(keyEvent)) {                // vla.a=New Window 和弦
        ama amaVar = vla.b(keyEvent);      // vla.b=和弦→action 解码
        if (amaVar != null && action==UP)
            bmaVar.a.f(amaVarB);           // 发射 action 到编辑管道
    } else if (action==UP && oim.a(config)) // New Window 仅 sw≥600dp
        bz5Var.invoke(null);               // 打开新窗口
}
```

- `oim.a(configuration)` = **`smallestScreenWidthDp >= 600`**——
  New Window 和弦为平板专属（手机丢弃 + "launcher not ready" 日志）。
- `qdn.a` 短路：文本域内按键不进入应用级和弦表。

## 三、其余 dispatch/lifecycle 语义

| 方法 | 语义 |
|------|------|
| `dispatchTouchEvent` | `fzm.d` 埋点 tap + `SecurityException` 经 `nxb` 守卫吞掉（遮挡窗口触摸的已知 Android bug 规避） |
| `dispatchGenericMotionEvent` | `fzm.b` 埋点（stylus/鼠标通用运动事件） |
| `onActivityResult(1123)` | **Play 应用内更新返回**：结果 ≠ RESULT_OK 时记 "AppUpdateFailed" 并弹 `p()` 阻断对话框（Cancelable=false，Update/Exit） |
| `onSaveInstanceState` | 持久化 `showWhenLockedPolicy` 布尔 |
| `onStart` → `r()` | `bub.a()` 策略 && 未显式关 → 动态 `setShowWhenLocked/setTurnScreenOn` |
| `onTopResumedActivityChanged` | 多窗口置顶时重跑配置处理 `n(configuration)` |
| `onUserInteraction` | `ow3.a` 单例打点（交互时间戳） |

## 四、强制更新对话框字符串族

`app__update_required_title/message` + `app__update_action_`
{exit,later,restart,update}——5 条 1.4.2 均在。阻断式（不可取消）。

## 五、Harmony 侧

- 无应用内更新检查/阻断对话框——Harmony 应用更新走应用市场
  系统机制，无 runtime 等价。**登记：原版 force-update 面不移植**。
- sw≥600dp 和弦门控：New Window 和弦本身未实现（827 缺口），
  门控规则一并登记；Harmony `PageManagerBar` 另有 600vp 宽度
  类适配（不同语义）。
- `showWhenLockedPolicy` 持久化：Harmony 无锁屏可达模式
  （826 已登记平台差），持久化键无对应。
- SecurityException 触摸守卫：Harmony 事件管线无对应 bug 模式，
  无需移植。
- onTopResumedActivityChanged：Harmony 多窗范式不同，无对应回调。

## 六、结论

MainActivity 15 个 override 全部归因：827（key/sensor）+
826（attrs）+ 本相位（dispatch 细节/更新流/锁屏策略持久化/
多窗回调/交互打点）。新增登记项：force-update 阻断流、
sw600 和弦门控、showWhenLockedPolicy 持久化键。

# Phase 834 — RecordingForegroundService 代码语义

证据：`decompiled_1.4.2/sources/.../record/RecordingForegroundService.java`

## 一、onStartCommand 合约

```java
boolean valid = zx7.r(intent.getStringExtra("process_token"), K);
startForeground(2001, b());                     // FGS id=2001
if (!valid) {                                    // 陈旧启动守卫
    log("stale start"); if (!G) stopSelf(i2); return START_NOT_STICKY; // =2
}
G = true;
zt5 st = M.G.getAndUpdate(new xt5(0));          // 会话计数状态机
if (!st.b || st.a > 1) {                        // 已有多会话→拒绝新启动
    stopSelf(i2); return 2;
}
c().acquire(wg4.g(I));                          // WakeLock 带超时时限
return START_NOT_STICKY;                        // =2
catch (ServiceStartNotAllowedException e) { a(e, i2, valid); }
```

- **`process_token` 校验**：K 为进程级 token——过期 start 指令
  （系统重启残留/旧令牌）直接 stopSelf。
- **会话单飞**：`zt5` AtomicReference 计数，多会话拒启动。
- **WakeLock 时限**：`wg4.g(I)` 包裹的超时获取（防永久持有）。
- **`a()` 拒绝降级**：startForeground 被拒（API31+ 限制）时
  按 `hi9.I/J` 分级记日志 + 条件 stopSelf。

## 二、通知构建 `b()`

- 懒建 channel `notability_recording`（静态 L 标志），
  importance=**2**（LOW——与 820 渠道表一致）；
- icon=`ui_designsystem__app_mark`，title=
  `feature_note_toolbox__recording_notification_title`；
- `flags |= 2`（FLAG_ONGOING_EVENT）+ `p=true`——**常驻不可
  划除**录音提示。

## 三、生命周期

- `onBind` → null（纯 started 服务）；
- `onCreate`：协程作用域 + 状态订阅（`tee.I`）；
- `onDestroy`：取消作用域 + `if held → release` wakelock。

## 四、Harmony 侧映射

| 原版 | Harmony | 状态 |
|------|---------|------|
| FGS + ongoing notification | `startBackgroundRunning(AUDIO_RECORDING, wantAgent)` 系统托管横幅 | 对齐（820） |
| process_token 陈旧守卫 | 无对应（单 ability 实例模型） | 登记 |
| 会话单飞 zt5 计数 | 录制状态机自身单例 | 对齐（语义保留） |
| WakeLock 时限 | Harmony 连续任务由系统续航托管 | 登记平台差 |
| ServiceStartNotAllowed 降级 | startBackgroundRunning 异常路径已捕获 | 对齐 |
| onBind=null | 无 IPC 面 | 一致 |

## 五、结论

录音 FGS 的可执行合约完整解码：FGS id 2001、token 守卫、
会话单飞、限时 wakelock、LOW 重要性常驻通知、拒绝降级。
Harmony 连续任务抽象覆盖核心语义（系统横幅+存活保证），
token/计数/wakelock 细节为平台差登记。

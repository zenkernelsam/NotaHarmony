# ADR-0189：原版麦克风录音的系统后台中断收尾

## 状态

Accepted，2026-08-14。

## 问题

`OriginalRecordingMicrophoneBackend` 原先只订阅 Harmony `AVRecorder` 的 `error` 事件，
`setInterruptionListener()` 是空实现。会话层虽然监听 `AudioSessionManager.audioSessionDeactivated`，但平台还可以
直接以系统原因改变 AVRecorder 状态；该状态变化不保证先经过应用音频会话回调。

当 recorder 已被系统自动置为 `stopped` 时，旧实现仍把控制器保持在 RECORDING。用户或中断回调随后调用
stop，后端又只接受 `started/paused`，于是抛错、进入 abort 并删除原本可以保存的录音文件。与此同时，会话的
统一中断处理会在调用 stop 前直接把 `focusActive` 清为 false；如果中断来自 backend 而不是 focus gateway，
真正仍激活的 Harmony AudioSession 将因此跳过释放。

## 原版与平台证据

- 原版 `decompiled_1.0.3/sources/defpackage/wr8.java`：AudioFocus 永久/瞬时丢失时，如果正在录音就向上游
  发出 interruption 信号；上游沿正常停止流程收尾，而不是静默保持“录音中”。
- 原版 `tr8.java`：MediaRecorder 启动时安装 `OnInfoListener` 与 `OnErrorListener`，不会只依赖外部 UI 状态
  猜测 recorder 是否仍在运行。
- Harmony SDK `@ohos.multimedia.media.d.ts`：AVRecorder `stateChange` 可由用户操作或系统触发，携带
  `StateChangeReason.USER/BACKGROUND`；状态集合包括 `paused`、`stopped` 与 `error`，且平台明确存在自动转为
  `stopped` 并以 BACKGROUND 报告的路径。

原版没有 Harmony AVRecorder API，因此具体事件接线属于平台适配；行为目标仍严格遵循原版“录音拥有者接收
中断并沿正常 stop/save 路径收尾”的语义。

## 决策

1. 麦克风后端在 `prepare/start` 前同时订阅 `error` 与 `stateChange`。
2. 只有属于当前 recorder、reason 为 `BACKGROUND` 且新状态为 `paused` 或 `stopped` 的事件才向上游报告
   interruption。USER 状态变化、`started`、`released` 与其他状态不触发。
3. 每个 recorder 实例最多报告一次后台中断，避免平台连续发送 paused→stopped 或与音频会话中断重复时产生
   多个保存请求。
4. stop 接受 `started`、`paused` 与已经 `stopped` 三种可收尾状态。只有前两者调用 `recorder.stop()`；对已经
   stopped 的输出直接注销 listener、release、校验普通非空文件并读取媒体时长，随后交给既有持久化流程。
5. `error` 仍保持失败语义：控制器 abort backend、删除不可信输出并发布 FAILED；本阶段不把 recorder error
   误当成可保存的正常中断。
6. release/dispose 在释放 recorder 前注销 state/error listener，并清空本实例中断去重状态，迟到回调不能影响
   新会话。
7. 会话的 `onCaptureInterrupted()` 不再预先修改 `focusActive`。所有中断都进入同一个串行 `stop()`；
   `stopInternal()` 在 capture 收尾后调用幂等 focus gateway deactivate。若中断来自 AudioSession gateway，
   gateway 已自行失活，重复 deactivate 无副作用；若来自 recorder，真实活动 focus 可以被正确释放。
8. focus 与 recorder 两路中断同时到达时，由 session/capture mutex 串行；第一条完成保存，后续请求看到非活动
   capture 后退出，不会重复发布录音。

## 结果

- 应用退后台、系统策略暂停/停止 recorder 等路径不再让 UI 永久停留在虚假 RECORDING。
- 已由系统完整停止且仍有有效字节的录音不再因非法第二次 stop 被删除，而是尽量按原版中断语义保存。
- backend 中断不再泄漏 Harmony AudioSession；focus 中断仍保持幂等。
- 用户主动 pause/stop 与 recorder error 行为不变。

## 边界

- 桌面 replay、ArkTS 编译和 session fake 覆盖事件分类、去重、已经 stopped 的收尾门以及 focus 释放；真实
  AVRecorder 回调顺序、后台权限策略、来电/抢占和媒体元数据可用性仍需设备验证。
- 若系统停止后文件为空、不是普通文件或 metadata/FD 校验失败，仍按既有失败路径删除，不能为了“尽量保存”
  接受损坏资产。
- 本阶段不在后台继续无限录音；它只安全保存系统中断前已经产生的内容。

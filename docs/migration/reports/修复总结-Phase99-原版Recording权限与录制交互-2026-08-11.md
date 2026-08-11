# Phase 99 修复总结：原版 Recording 权限与录制交互

## 原版证据

- `xjb` 将 `tjb/ujb/rjb/sjb` 分别映射到 start、stop、pause、resume；`i5h` 在 start 前通过
  `fha.RECORD_AUDIO` 请求权限，并分别显示 `Couldn't start recording` 与
  `Couldn't save recording`。
- `wr8` 使用 gain type 1、usage 1、content type 1 的 audio focus；`tr8` 在 recorder start
  前请求焦点，永久或瞬时 focus loss 都会中断本次录音。
- 关闭 Recording toolbox 时，原版会先触发 stop；权限拒绝说明使用
  `Microphone Access Required`，并提示用户前往应用设置开放麦克风。

## 已完成修复

- 新增串行 `OriginalRecordingSessionController`，统一协调运行时权限、卸载播放器、音频会话、
  capture、Phase 98 持久化与最终 release。开始顺序固定为
  `permission -> playback unload -> focus -> capture`，stop 后先释放焦点再保存。
- 新增 Harmony 权限与音频焦点 gateway：按用户动作调用
  `AtManager.requestPermissionsFromUser`；使用 media scene 与 `CONCURRENCY_PAUSE_OTHERS` 激活
  audio session，收到 `audioSessionDeactivated` 后自动走同一 stop/save 路径。
- `RecordingPanel` 新增固定高度的 Record/Pause/Resume/Stop 控制行、实时 elapsed、preparing 与
  saving 状态；保留原有录音列表、累计 seek、播放速度、删除/撤销与资产状态显示。
- `NotePage` 完成生产接线：start 前卸载现有播放器，stop 结果进入原子 Recording 创建持久化；
  关闭面板会等待活动录音保存，即使 close 与尚未完成的 start 竞态也会排队 stop；离开编辑器先
  `finishAndRelease`，生命周期回调提供幂等兜底，不再直接 abort 丢弃有效录音。面板内部关闭键与
  顶部 Recordings 切换键统一走相同关闭路径，不会留下不可见的后台录音。
- 权限拒绝、start 失败和 save/stop 失败分开建模并只上报一次；补齐中英文原版式权限说明、
  start/save 错误及录制控制资源。边修边审修正活动录音的异步 recorder error：只有 STARTING
  失败归入 start error，RECORDING/PAUSED/STOPPING 失败均按原版 save error 上报。
- 边修边审更新 Phase 97/88 的历史 replay 边界：页面现由 session 管理 capture，面板只发命令，
  仍不直接依赖底层 recorder、数据库或资产持久化。

## 验证

- 专项 replay：
  `recordingSession=permission-focus-interruption-controls-close-save-release`。
- 全量桌面 replay：`TOTAL=85 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动模拟器或真机，未执行设备 Hypium。运行时权限弹窗、真实麦克风、AAC/MPEG-4 codec、
  音频会话打断、扬声器共存和各尺寸面板布局留给设备验收，不虚报完成。

## 剩余边界

录音主链现在已从权限、采集、暂停/继续、停止、焦点中断、资产入库到 operation journal 闭环。
后续仍需结合原版继续处理波形/录音相关剩余 consumer、私有同步 upload/ACK，以及设备实测暴露的
权限、codec、音频路由和交互问题。Goal 保持 active，继续边修边补审。

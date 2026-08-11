# Phase 100 修复总结：原版 Recording 列表标题与时间副标题

## 原版证据

- `hkb` 给每条可见 Recording 分配一基索引；无 segments 时使用 Recording start 与完整有效时长，
  有 segments 时只使用第一段 start 和 `end-start`。
- `n05` 不显示 Recording `name` 或资产文件名作为标题，而是使用 `Recording %1$s`；时长严格分为
  `h m s`、`m s`、`s` 三种格式，再与 locale medium date、short time 组合为
  `%1$s %2$s, %3$s`。
- 对 1.0.3 生产录音链搜索后未发现 amplitude 采样或波形生成路径；唯一 `getMaxAmplitude` 位于无关的
  Samsung wrapper，因此本阶段不虚构所谓原版波形。

## 已完成修复

- 新增 `OriginalRecordingPresentation`，复用已校验的首段有效时长规则，并按原版选择 Recording start
  或第一段 start。uint64 十进制时间只有在 JavaScript Date 安全范围内才转换，避免静默精度损失。
- 新增原版精确时长格式：`1h 1m 1s`、`1m 5s`、`59s`；毫秒按原版向下取整到秒。
- `RecordingPanel` 标题改为按可见顺序本地化显示 `Recording N / 录音 N`，不再把
  `recording_时间戳_序号.m4a` 一类内部文件名暴露给用户。READY 项显示时长、日期与时间。
- PENDING/MISSING/FAILED 项仍优先显示资产状态；异常旧时间无法安全转 Date 时只回退 subtitle，
  不让单条异常 Recording 拖垮整个列表或阻止可用资产播放。
- 补齐中英文标题和 subtitle 参数资源，新增 ArkTS presentation 测试与专项 replay。

## 验证

- 专项 replay：`recordingPresentation=ordinal-first-segment-hms-local-date-time`。
- 全量桌面 replay：`TOTAL=86 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动模拟器或真机，未执行设备 Hypium；locale 实际文案和窄屏行布局留给设备验收。

## 剩余边界

Phase 99 的真实权限、麦克风、codec、音频焦点与路由仍待设备验收；私有同步 upload/ACK 仍是独立工作。
波形只有在继续反编译找到原版真实数据源与行为后才应实现，不能用装饰动画冒充功能。Goal 保持 active。

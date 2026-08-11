# Phase 95 修复总结：原版 AudioLinked 笔迹播放

## 原版证据

- `dm2.j()` 明确把 CREATE_INK field 15 读取为 nullable uint32 `audioDuration`；`s06.c()/m()`
  分别给出 `operation.audioTime ?? clientTime` 的起点与起点加 duration 的终点。
- `s1j.b()` 以 unsigned 时间比较产生 Unbegun、Animating、Complete；终点小于起点属于 invariant
  violation，直接 Complete。`p16.a()` 还要求 Ink 起点落在可见 Recording segment 中。
- `p16/i16/e16` 证明 Unbegun/Animating 的完整旧内容 alpha 固定为 0.3；Animating 再以正常 alpha
  覆盖已完成前缀。Pencil 按 splat 数量截断，普通 Ink 按路径长度截断。

## 已完成修复

- field 15 改为精确 nullable uint32 解码，移除错误的
  `CREATE_INK_AUDIO_DURATION_UNSUPPORTED` deferred 门；CREATE_INK 将 effective audio start 与
  duration 写入笔迹快照。
- ADD_PATH_ELEMENTS、MODIFY_INK、擦除、选区变换、剪贴板与编辑器深复制均保留 audio metadata，
  避免后续几何/样式操作使笔迹退出播放时间线。
- 新增纯 `OriginalAudioLinkedInkPlayback`：完整保留 uint64 十进制精度、Recording segment inclusive
  守卫、0.3 alpha、三态进度和原版 invalid-end 行为；本地 player position 映射到当前录音第一有效段的
  绝对 audio time。
- 播放上下文进入画布后强制复用现有 unified ordered renderer，不复用无法随时间变化的 completed bitmap，
  因而 Stroke/Text/Shape/Image/Math 的原层序不被打乱。播放结束或失败后回到静态缓存路径。
- Unbegun 绘制 0.3 alpha 完整笔迹；Animating 先绘制 0.3 alpha 完整笔迹，再正常 alpha 覆盖前缀。
  Pencil 取 `floor(splatCount * progress)`；普通折线/Bezier 按几何长度取前缀，终端 cubic 以
  de Casteljau 分割并插值宽度/压力属性。
- 旧 JSON 快照从 Phase 94 的 applied-only timing reader 按 CREATE operation ID 恢复 effective start。
  旧实现会 deferred 所有非空 field 15，因此历史已物化笔迹不存在“duration 被静默丢失”的升级歧义。

## 验证

- ArkTS 新增状态、uint64、segment、player absolute-time、Pencil 与普通路径截断测试；CREATE_INK fixture
  新增 uint32 max field 15 并确认 preflight 放行。
- 专项 replay：`D02_AUDIO_LINKED_INK_PLAYBACK_OK`。
- 全量桌面 replay：`TOTAL=81 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning，无编译错误。
- 未启动模拟器或真机。

## 剩余边界

本阶段关闭的是原版 AudioLinked Ink 的静态代码闭环，不虚报设备上的实际音频 decode、回调节奏、动画平滑度
或 Android 像素级对照。波形、录音采集、audio focus/输出路由、Recording rename/delete outbound 与私有同步
transport 仍是后续独立工作；Goal 保持 active。


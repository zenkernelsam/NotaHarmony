# ADR-1122：内嵌媒体纹理节点（vfc）

## 状态

已接受（Phase 1178）。

## 决策

`vfc` = 嵌入媒体纹理节点：`SurfaceTexture`（媒体解码帧
→GL 纹理桥）+ `q0b`/`m40`/`r71` 帧队列 + `c(ot4,
MediaFormat)` 喂帧 —— `bpd` SceneRenderer 把嵌入视频/
PDF 当 GL 纹理与墨迹/文本同帧合成。

## 理由

`SurfaceTexture R` + `MediaFormat` + 帧队列 + `float[16]`
纹理矩阵；`bpd` 引用 `vfc.SurfaceTexture`。

## Harmony 映射

- `SurfaceTexture` → `nativeImage`/ImageReceiver/XComponent
  帧→纹理桥。
- `MediaFormat` 解码 → `AVCodec`/`AVPlayer`。
- 帧队列 → 缓冲队列。

## 后果

Harmony 嵌入媒体渲染 = 解码帧→纹理桥→场景纹理，
与墨迹同帧合成 —— 媒体播放/渲染管线重适配 AVCodec。

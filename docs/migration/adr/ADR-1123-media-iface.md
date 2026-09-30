# ADR-1123：媒体喂帧 iface + renderer 生命周期

## 状态

已接受（Phase 1179）。

## 决策

- `zxf.c`/`nc1.a` = 解码器→纹理节点喂帧/矩阵 iface —
  producer-consumer 解耦（帧队列缓冲）。
- `bpd` 生命周期 `onSurfaceCreated/Changed/DrawFrame`
  → Harmony XComponent surface 回调。

## 理由

`zxf{void c}`、`nc1{void a,void b}` iface + `vfc` 实现 +
`bpd` GL10/EGLConfig 生命周期。

## Harmony 映射

喂帧回调 → `AVCodec`/`ImageReceiver` `onFrame`；
surface 生命周期 → `XComponent` 回调。

## 后果

媒体解码与 GL 渲染解耦；Harmony 用 AVCodec 帧回调
+ XComponent surface 生命周期对齐。

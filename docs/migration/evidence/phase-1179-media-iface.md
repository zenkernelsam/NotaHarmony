# Phase 1179 证据 — 媒体喂帧 iface（zxf/nc1）+ bpd 表面生命周期

来源：`defpackage/{zxf,nc1,bpd}.java`。

## iface 契约

```java
zxf: void c(long, long, ot4, MediaFormat)   // 解码器→纹理喂帧
nc1: void a(long, float[]); void b()        // 解码器→纹理矩阵更新
```

`vfc implements zxf,nc1` —— 媒体解码器经这两 iface 把
解码帧(`c`)+帧矩阵(`a`)推进纹理节点；`bpd` 通过 `vfc`
同帧合成。

## `bpd` Renderer 生命周期

```java
onSurfaceCreated(GL10,EGLConfig)   // 建 GL 资源
onSurfaceChanged(GL10,w,h)         // 视口
onDrawFrame(GL10)                  // MVP 链+draw+媒体
```

## 判定

媒体管线：解码器 → `zxf.c`/`nc1.a` 喂入 `vfc` →
`bpd.onDrawFrame` 统一合成 —— 解码与渲染解耦（
producer-consumer，帧队列缓冲）。

## Harmony 决策

- iface → Harmony 帧回调（`AVCodec`/`ImageReceiver`
  `onFrame`）。
- `bpd` 生命周期 → XComponent surface 回调
  （`onSurfaceCreated/Changed/Destroyed`）。

## 产出

- fixture `d02-media-iface.mjs`（10 断言）。
- ADR-1123；中文报告。

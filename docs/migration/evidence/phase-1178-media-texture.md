# Phase 1178 证据 — 内嵌媒体纹理节点（vfc → SceneRenderer）

来源：`defpackage/vfc.java` + `bpd` 引用。

## `vfc implements zxf, nc1` = 内嵌媒体纹理场景节点

```java
vfc:
  SurfaceTexture R                 // 媒体→GL 纹理桥
  AtomicBoolean I,J                // 帧/就绪标志
  q0b K                            // 帧队列
  m40 L(3)                         // 帧队列(容量3)
  r71 M,N(8)                       // 帧队列(×8)
  float[16] O,P                    // 纹理矩阵
  a(long,float[])                  // 帧→矩阵更新
  c(long,long,ot4,MediaFormat)     // 媒体帧喂入
    jbj.c(x6a)  // 帧→队列
```

## 判定

**嵌入媒体经 SurfaceTexture→GL**：笔记场景的嵌入
视频/PDF/媒体用 `SurfaceTexture` 接收解码帧 →
`bpd` SceneRenderer 把它当 GL 纹理绘入画布 ——
与墨迹/文本同帧合成。

`MediaFormat`/`ot4`/`x6a`/`jbj` = Android 媒体解码类型
（帧→队列→纹理）。

## Harmony 决策

- `SurfaceTexture` → Harmony **`nativeImage`/`XComponent`
  或 ImageReceiver**（解码帧→纹理桥）。
- `MediaFormat` 解码 → Harmony `AVCodec`/`AVPlayer`。
- 帧队列 `q0b/m40/r71` → Harmony 帧缓冲队列。

## 产出

- fixture `d02-media-texture.mjs`（10 断言）。
- ADR-1122；中文报告。

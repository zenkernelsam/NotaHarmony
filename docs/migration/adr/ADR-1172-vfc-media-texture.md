# ADR-1172：vfc 媒体纹理/360 立体节点

## 状态

已接受（Phase 1228）。

## 决策

`vfc` SurfaceTexture GL 媒体节点 + `ot4.C` csd →
`x6a`/`jbj` 立体元数据 + 默认等距球面 mesh（15984/
10656）→ Harmony `AVPlayer`+`XComponent` 纹理 +
自研 360 mesh。

## 理由

`vfc` csd 解析（magic 1886547818 box → `o0b`/`p0b`
立体对）+ 180/360 radians 球面顶点 + `ufc`
OnFrameAvailable —— 笔记内嵌 360/VR 视频渲染。

## 后果

Harmony 媒体嵌入 = AVPlayer 纹理输出 + XComponent +
自研球面 mesh —— 360 播放语义保真。

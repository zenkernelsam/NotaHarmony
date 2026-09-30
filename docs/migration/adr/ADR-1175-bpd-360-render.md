# ADR-1175：bpd 360 头追渲染循环

## 状态

已接受（Phase 1231）。

## 决策

`bpd` Renderer+dv9+MVP 链+逐帧旋转+立体 mesh →
Harmony XComponent GLES2 + sensor 逐帧旋转 +
AVPlayer 纹理 —— 360 头追。

## 理由

`bpd.a` 存 `L`/`M` 相机运动折进 view；`onDrawFrame`
`updateTexImage`+ts→`m40` 逐帧旋转矢量→`vfc.O`+
`p0b`/`r71` 立体 mesh+`vfc.P=K×O` —— 360 视频头追。

## 后果

Harmony 360 渲染 = XComponent+sensor 逐帧矩阵+纹理
—— 头追语义保真。

# ADR-1121：GL 笔记画布（GLSurfaceView + SceneRenderer）

## 状态

已接受（Phase 1177）。

## 决策

- 笔记编辑面 = **OpenGL ES 2.0 `GLSurfaceView`** →
  Harmony **`XComponent`** + OpenGL/Vulkan（首选 ES2
  对等，XComponent GL surface）。
- `bpd`=`SceneRenderer`：`onDrawFrame` MVP 链
  `K=J×(M×(L×N))` + `setRotateM` 朝向旋转 → Harmony
  渲染器矩阵乘法语义保留。
- `ev9` 显示方向适配 → Harmony display 监听。

## 理由

`extends GLSurfaceView`、`EGLContextClientVersion(2)`、
`implements GLSurfaceView.Renderer`、`Matrix.multiplyMM`
MVP 链、`nhi.d("SceneRenderer")` 实名。

## 后果

Harmony 画布 = XComponent GL surface + ES2 renderer；
MVP/旋转/缩放矩阵沿用；低延迟墨迹 GPU 渲染路线
对齐原版。

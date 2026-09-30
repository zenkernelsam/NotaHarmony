# Phase 1177 证据 — GL 笔记画布（cpd GLSurfaceView + bpd SceneRenderer）

来源：`defpackage`（obf）GL 渲染类。

## `cpd extends GLSurfaceView` —— 笔记画布（OpenGL）

```java
setEGLContextClientVersion(2)      // **OpenGL ES 2.0**
setRenderer(new bpd(this, vfc))    // bpd = GL Renderer
OnTouchListener = new aaf(ctx, bpd)
L = new ev9(WindowManager.display, aaf, bpd)  // 显示方向
```

笔记编辑面 = **GLSurfaceView**（非软件 Canvas）——
低延迟墨迹经 GPU 渲染。

## `bpd` = **`SceneRenderer`**（实名，`nhi.d("SceneRenderer")`）

```java
bpd implements GLSurfaceView.Renderer, dv9:
  Matrix.setIdentityM ×3                    // J/L/M 初值
  Matrix.setRotateM(M,0,-O,cos(f2),sin(P)) // 旋转
  onDrawFrame(GL10):
    multiplyMM(R, L, N)   // R=L×N
    multiplyMM(Q, M, R)   // Q=M×R
    multiplyMM(K, J, Q)   // K=J×Q  ← MVP 链
    nhi.d("SceneRenderer","Failed to draw a frame")
```

**MVP 矩阵链**：`K = J × (M × (L × N))` ——
model/view/projection 乘法 + setRotateM 朝向旋转。

`ev9` = 显示-方向适配（WindowManager display → aaf/bpd）。

## 判定

**笔记画布 = OpenGL ES 2.0 渲染**：`ka8` 笔画（Phase
1176）转 GL 几何 → `bpd` SceneRenderer 帧绘 —— GPU
低延迟墨迹 + 旋转/缩放（手势）经 MVP 矩阵。

## Harmony 决策

- `GLSurfaceView` → Harmony **`XComponent`** + OpenGL/
  Vulkan（或 `Drawing`/ArkUI `Canvas`）。
- `bpd` SceneRenderer MVP 链 → Harmony 渲染器（矩阵
  乘法语义保留）。
- `ev9` 显示方向 → Harmony display 方向监听。

## 产出

- fixture `d02-gl-canvas.mjs`（10 断言）。
- ADR-1121；中文报告。

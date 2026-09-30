# Phase 1231 证据 — bpd SceneRenderer 360 头追渲染循环

来源：`defpackage/{bpd,vfc,q0b,r71,m40,p0b,nlh,nhi}.java`。

## `bpd.a(roll,matrix)` = 相机运动→视差

```java
public final synchronized void a(float f, float[] fArr) {
    L = fArr;                              // 相对旋转
    P = -f;                                // -roll
    M = setRotateM(-O, cos(-f), sin(P),0); // 滚转倾斜
}
```

## `onDrawFrame` = MVP 链 + 360 帧管线

```java
Q = M×(L×N);  K = J×Q;          // view×camera-motion
glClear; nlh.a();
if (vfc.I CAS) SurfaceTexture.updateTexImage();
ts = getTimestamp();
Long l = vfc.M.E(ts);            // ts→帧时刻
fArr4 = m40.M.G(l);              // 该帧的旋转矢量!
// 轴角 → setRotateM → 相对 → vfc.O  (逐帧头追同步)
p0b = vfc.N.G(ts);               // 该帧立体元数据
q0b.b(p0b)→stereo type+r71 FloatBuffer mesh
vfc.P = K × vfc.O               // final = view×model
glUniformMatrix3fv/4fv + draw sphere mesh
perspectiveM(J, fov90/aspect, 0.1, 100)
```

## 语义

- `a` 回调存 `L`=相对旋转 + `M`=滚转 —— **设备倾斜
  折进 view 矩阵** → 整个媒体/360 视图平移；
- 帧管线：`updateTexImage` + `getTimestamp` → `m40`
  **逐帧旋转矢量**（时间戳→旋转）→ `vfc.O` 模型矩阵
  —— **360 视频头追**：设备转动 → 球面视角跟随；
- `p0b`/`r71` = 每帧立体 mesh（FloatBuffer 顶点/UV
  + stereo type 4/5/6）；
- `vfc.P = K×O` = 投影×视差×模型 → sphere 纹理绘制；
- `nlh`/`nhi` = GlUtil + 日志（"SceneRenderer" tag）。

## Harmony 决策

GLSurfaceView.Renderer + SensorTexture + 逐帧旋转 →
Harmony XComponent GLES2 + AVPlayer 纹理 + sensor
逐帧旋转矩阵 —— 360 头追保真。

## 产出

- fixture `d02-bpd-360-render.mjs`（10 断言）。
- ADR-1175；中文报告。

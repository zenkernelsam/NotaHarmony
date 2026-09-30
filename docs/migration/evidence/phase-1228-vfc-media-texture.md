# Phase 1228 证据 — vfc 媒体纹理/360 立体节点

来源：`defpackage/{vfc,ot4,x6a,jbj,o0b,p0b,q0b,r71,m40,ufc}.java`。

## `vfc implements zxf,nc1` = GL 媒体纹理节点

```java
SurfaceTexture R;
AtomicBoolean I,J;                 // 帧可用/重建标志
q0b K; m40 L; r71 M,N;             // 帧队列×4
float[] O,P;                       // 纹理矩阵×2
```

`c(ts,dur,ot4,MediaFormat)` = 解码器推送帧元数据：
`M.b(dur→ts)` 时间戳映射 + `ot4.C`=**csd 编解码
特定数据** + `ot4.D` 格式索引。

## `ot4.C` = csd → 360 立体元数据解析

```java
x6a reader = new x6a(csdBytes);
reader.N(4); if (reader.m() == 1886547818) {  // magic box
    // 遍历 box → o0b 立体对视信息
    arrayList = jbj.c(reader);
    p0b = new p0b(o0b1, o0b2, type);  // 立体对
}
```

`x6a` = 字节读取器（`N`/`M`/`L`/`m` 跳过/定位/读int）；
`jbj.c` = box 解析 → `o0b` 列表（左右眼/projection）。

## 无元数据 → 默认 equirectangular 球面 mesh

```java
float radians = toRadians(180), radians2 = toRadians(360);
float[] fArr  = new float[15984];   // 顶点缓冲
float[] fArr2 = new float[10656];   // UV 缓冲
// 循环细分球面 → r71 帧缓冲
```

**360° 全景视频默认按等距圆柱投影球面渲染** ——
笔记内嵌 360/VR 视频。

## `d()` = SurfaceTexture 惰性创建

```java
SurfaceTexture st = new SurfaceTexture(this.Q);  // GL tex id
st.setOnFrameAvailableListener(new ufc(){onFrameAvailable});
```

解码器输出 → SurfaceTexture → `updateTexImage` →
GL 纹理 —— 视频/360 媒体嵌进笔记场景（Phase 1178
收敛）。

## Harmony 决策

`SurfaceTexture`/`MediaFormat`/csd 解析 → Harmony
`AVPlayer`+`XComponent` 纹理输出 + 自研 360 mesh
（球面顶点缓冲 15984/10656 对齐）；`ot4.D` 格式索引
→ 轨类型枚举。

## 产出

- fixture `d02-vfc-media-texture.mjs`（10 断言）。
- ADR-1172；中文报告。

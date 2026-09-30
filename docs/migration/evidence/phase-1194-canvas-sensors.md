# Phase 1194 证据 — 画布传感/媒体面（cpd 全字段）

来源：`defpackage/{cpd,o44,ubd,b94}.java`。

## `cpd extends GLSurfaceView` = 全功能笔记画布

```java
cpd:
  CopyOnWriteArrayList I    // surface attach/detach 监听
  SensorManager J + Sensor K // **运动传感（camera-motion）**
  ev9 L                      // 显示方向适配
  Handler M
  vfc N                      // 媒体纹理节点（Phase 1178）
  SurfaceTexture O, Surface P// 媒体 surface
  boolean Q,R,S              // 渲染标志
  a(): registerListener(ev9,K,0)/unregister
  getCameraMotionListener()→nc1
  getVideoFrameMetadataListener()→zxf
```

## 判定

`cpd` = GL 画布含**运动传感相机**（SensorManager→
`ev9`→`nc1` 相机矩阵 —— 视差/倾斜效果）+ **视频帧渲染**
（SurfaceTexture→`zxf`→`vfc` 媒体纹理）+ `CopyOnWrite`
surface 监听 —— 远超纯墨迹：媒体嵌入 + 传感器驱动。

`o44 implements zxf,nc1,ypa` = 桥接 sensor/video 帧到
`nc1`/`zxf`；`ubd`/`b94` Runnables 管 `cpd` 的
`SurfaceTexture O`/`Surface P` 换绑。

## Harmony 决策

- `SensorManager`/`Sensor` → Harmony `@ohos.sensor`
  （加速度/陀螺仪 —— 相机视差驱动）。
- `SurfaceTexture`/`Surface` → Harmony `nativeImage`/
  ImageReceiver。
- 相机矩阵 `nc1` + 视频帧 `zxf` → Harmony 帧回调。

## 产出

- fixture `d02-canvas-sensors.mjs`（10 断言）。
- ADR-1138；中文报告。

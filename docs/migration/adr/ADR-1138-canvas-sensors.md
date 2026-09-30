# ADR-1138：画布传感/媒体面

## 状态

已接受（Phase 1194）。

## 决策

`cpd` GL 画布含**运动传感相机**（`SensorManager`/`Sensor`/
`ev9`→`nc1` 相机矩阵 —— 视差）+ **视频帧渲染**
（`SurfaceTexture`/`Surface`/`vfc`→`zxf`）→ Harmony
`@ohos.sensor`（加速度/陀螺）+ `nativeImage`/ImageReceiver
帧桥 + `XComponent`。

## 理由

`SensorManager`+`Sensor`+`registerListener` + `SurfaceTexture
O`/`Surface P` + `getCameraMotionListener`/`getVideoFrameMetadata`
+ `vfc` + `CopyOnWriteArrayList`。

## 后果

Harmony 画布 = XComponent GL + sensor 视差相机 +
媒体帧纹理 —— 运动传感 + 视频嵌入管线重适配。

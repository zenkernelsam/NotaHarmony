# Phase 1230 证据 — cpd GL 画布编排（sensor+listener API）

来源：`defpackage/{cpd,ev9,vfc,bpd,aaf,b94}.java`。

## `cpd extends GLSurfaceView` 构造编排

```java
SurfaceTexture O; Surface P;            // 视频面
SensorManager J; Sensor K;              // 传感器
vfc N;                                  // 媒体节点
bpd renderer; aaf touch; ev9 cameraMotion;

cpd(context) {
    K = sm.getDefaultSensor(15) or 11;   // GAME_ROTATION→ROTATION
    N = new vfc();
    renderer = new bpd(this, vfc);
    aaf = new aaf(context, bpd);
    L = new ev9(display, aaf, bpd);       // dv9[]=[aaf,bpd]
    setEGLContextClientVersion(2);         // GL ES 2.0
    setRenderer(bpd); setOnTouchListener(aaf);
}
```

## Sensor 门控 + listener API

```java
a() { if ((Q&&R) != S) register/unregister ev9; }
// Q=useSensorRotation(默认 true) R=resumed S=已注册
getCameraMotionListener()    → N (vfc implements nc1)
getVideoFrameMetadataListener() → N (vfc implements zxf)
getVideoSurface()            → P (Surface)
setDefaultStereoMode(i)      → N.S (vfc 立体回退类型!)
setUseSensorRotation(b)      → Q → a()
onDetachedFromWindow → M.post(b94(this,19))  // 拆除
```

## 语义

- Sensor **15=GAME_ROTATION_VECTOR** 回退 **11=ROTATION_VECTOR**
  —— 免磁力计校准的旋转；
- `ev9(display, aaf, bpd)` —— **dv9 监听 = aaf 触控渲染 +
  bpd 场景渲染**（触控也接收相机运动 → 手势期间视差同步）；
- `vfc N` 既是 `nc1`（camera-motion tex-matrix）也是 `zxf`
  （视频帧元数据）——媒体/相机双职责；
- `setDefaultStereoMode` → `vfc.S` 立体格式索引；
- sensor 仅在 `Q&&R` 时注册（resumed 门控）。

## Harmony 决策

GLSurfaceView+sensor 编排 → Harmony `XComponent` +
`sensor` GAME_ROTATION_VECTOR + 门控注册；
`bpd`/`aaf`/`vfc` 三职责 → GL 渲染器+触控+媒体节点。

## 产出

- fixture `d02-cpd-orchestration.mjs`（10 断言）。
- ADR-1174；中文报告。

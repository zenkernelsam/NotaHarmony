# ADR-1216：Rive 动画运行时

## 状态

已接受（Phase 1272）—— **fail-closed 备选**。

## 决策

Rive → Harmony `rive-ohos`（若有）/Lottie/帧动画替代；
Native Skia → `XComponent`+Native 渲染。

## 理由

`RiveAnimationView`（TextureView+RiveFileController+
StateMachine+CDN-Volley）—— Native Skia 动画引擎，
Harmony 无官方 Rive 原生移植 —— fail-closed 到
Lottie/帧动画。

## 后果

Harmony 动画 = rive-ohos 若可用，否则 Lottie/帧动画
—— 动画语义部分保真（StateMachine 交互降级）。

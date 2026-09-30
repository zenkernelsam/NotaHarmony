# Phase 1272 证据 — Rive 动画运行时（app/rive 259 文件）

来源：`app/rive/runtime/kotlin/*`（259 文件）+ `defpackage/
{ta2,z39,pd,d5c,e5c,s37,f5c,h26}.java` 消费。

## `RiveAnimationView extends RiveTextureView`

```java
implements Observable<RiveFileController.Listener> {
    RendererAttributes rendererAttributes;
    Companion INSTANCE;  // rendererIndexDefault=Rive.getDefaultRendererType
    Builder (setRiveResource/setRiveBytes/setArtboardName/
             setAnimation/setStateMachineName/setAutoplay/...)
}
```

## 运行时分层

- `core/` —— `Rive`（Native 库）、`File`、`Artboard`、
  `StateMachineInstance`、`RendererType`（Skia/Canvas/
  LowSpec）、`Observable`/`Listener`；
- `renderers/` —— `Renderer`、`RendererMetrics`、
  `RiveArtboardRenderer`、`RendererSkia`/`RendererOpenGL`；
- `CDNAssetLoader` —— **Volley** 拉 CDN 资源；
- `controllers/` —— `RiveFileController`（play/pause/
  advance state machine）。

## App 消费

`ta2`/`z39`/`pd`/`d5c`/`e5c`/`s37`/`f5c`/`h26` —
— UI 动画/加载指示/插画播放（.riv 资源）。

## 语义

**完整 Rive 动画运行时** —— Native Skia 渲染 +
StateMachine + CDN 资产 —— App 用 .riv 做富动画。

## Harmony 决策

Rive → Harmony `@rive`/`rive-ohos`（若有）或 `Canvas`+
帧驱动回退；Native Skia → `XComponent`+Native 渲染 —
— 动画引擎 fail-closed：Harmony 无 Rive 原生时用
Lottie/帧动画替代。

## 产出

- fixture `d02-rive.mjs`（10 断言）。
- ADR-1216；中文报告。

# Phase 1319 证据 — 入站分流层（want/intent 处理）

来源：`data/{DeepLinkIngress,LaunchActionIngress,
OpenTargetIngress,OriginalDragDropIngress,Original
ClipboardImageIngress,OriginalCameraPickerCaller}.ets`。

## 各入站源（对照原版 intent/extra）

```
DeepLinkIngress       notability.com/app/note URIs +
                      authlink(VerifyLink yy2)+gallery
                      (1.4.2)+/event/*；py2.f/py2.a/m18.r0
                      规则；fail-closed：子域通配不支持
LaunchActionIngress   CREATE_NOTE intent + start_camera/
                      start_recording extras → hv7.i；
                      postCardAction launch_action 参数
OpenTargetIngress     want.uri/parameters 打开目标
                      （文件打开）→ normalizeDeepLinkNoteId
OriginalDragDropIngress   unifiedDataChannel 拖放→
                          image bytes→OriginalImageNormalizer
OriginalClipboardImage  pasteboard 剪贴板→image→normalizer
  Ingress
OriginalCameraPicker    cameraPicker.pick（IMAGE_CAPTURE
  Caller                等价）→importOriginalPhotos
```

## 语义

**入站分流层** —— 所有外部输入（深链/启动动作/文件
打开/拖放/剪贴板/相机）经 `Original*Ingress`/`Caller`
统一分流，逐条对照原版 intent/extra 规则（`py2.f`/
`hv7.i`/`yy2`）；不支持语义 fail-closed。

## Harmony 决策

Android intent/extra/URI → Harmony `Want`(uri/parameters)
+ `unifiedDataChannel`(拖放）+`pasteboard`+`cameraPicker`
—— 入站分流语义保真+fail-closed 边界。

## 产出

- fixture `d02-ingress-layer.mjs`（10 断言）。
- ADR-1263；中文报告。

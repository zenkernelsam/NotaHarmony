# Phase 1319 报告 — 入站分流层

## 完成内容

- `Original*Ingress`/`Caller` 入站分流：`DeepLinkIngress`
  （notability.com URIs+authlink+gallery+/event/*+fail-
  closed 子域）、`LaunchActionIngress`(launch_action+
  start_camera/start_recording)、`OpenTargetIngress`(want.
  uri)、`OriginalDragDropIngress`(unifiedDataChannel)、
  `OriginalClipboardImageIngress`(pasteboard)、`Original
  CameraPickerCaller`(cameraPicker) —— 对照原版 intent/
  extra 规则，外部输入统一分流+fail-closed。

## 产出

- evidence `phase-1319-ingress-layer.md`
- fixture `d02-ingress-layer.mjs`（10/10）
- ADR-1263

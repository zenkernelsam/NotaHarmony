# Phase 1231 报告 — bpd 360 头追渲染

## 完成内容

- `bpd`=SceneRenderer：`a(roll,matrix)` 存 L/M 相机
  视差；`onDrawFrame` `K=J×Q` + `updateTexImage` +
  ts→`m40` 逐帧旋转 + `p0b`/`r71` 立体 mesh + `vfc.P`
  = K×O —— 360 视频头追渲染。

## 产出

- evidence `phase-1231-bpd-360-render.md`
- fixture `d02-bpd-360-render.mjs`（10/10）
- ADR-1175

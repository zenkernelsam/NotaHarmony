# ADR-0906 — `z0c` 写器函数全映射

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`z0c` = synthetic Function0；case21=mx7 结构表、
case24=IdentityHashMap 表注册表。λ 归并为 `yec`/`ywd`
共享类，`switch(序数)` 分派"哪个写器"。

**15 结构写器全名**：vfj.d=xq3、rh8.O=qo5、fsi.b0=vy7、
apb.Y=fqa、ddj.b=ukb、ldj.A2=bmb、aa6.x0=ua0、efj.b=cwb、
nti.X=cxc、apb.Z=qed、wtf.b=utf、rz1.b0=v01、y5j.c=hd1、
z5c.P=hu1、内联=yyd。

**23 表写器名**（tsi.c=uf7 至 j7j.c=sw9）——
型→写器函数映射成为显式证据。

## Harmony 决策

Harmony 注册表镜像全部映射；未注册型 throw（与 rgc.b 一致）。

## Parity 状态

等价。

## 验证

- `d02-z0c-writer-map.mjs`：43/43 通过。
- 全量 Replay 835 文件绿，见 Phase 962 提交。

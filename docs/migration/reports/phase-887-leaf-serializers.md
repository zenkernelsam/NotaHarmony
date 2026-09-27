# Phase 887 报告 — 叶级字段序列化器

## 范围

登记内联结构与字段写器链末端。纯审计，无源改动。

## 原版发现

- `apb.Z`=qed 8B {d,c}；`fsi.b0`=vy7 16B {f,c,d,e}；
  `rh8.O`=qo5 8B {site,pad,timestamp}；`rh8.b`=qo5 构造。
- qo5=8B vs cxc=12B 两级位置标识分层实证。
- `fag.n0`→`o0`：k3a 六访问器；`j7j.c`：sw9={wa0+8B 结构
  向量}（zwd.a、负长守卫）。
- `apb.h`/`fsi.f` = qed/vy7 值类构造。
- `vv7.M` 委托四写器全部坐实。

## Harmony 核对

8B/12B 结构与 2f/4f 写已逐字节对齐；k3a↔背景模型、
sw9↔PDF 布局编码。

## 产出

- 证据：`phase-887-leaf-serializers.md`
- Fixture：`d02-leaf-serializers.mjs`（17/17）
- ADR-0831；全量 Replay 与双 HAP 结果记录于提交。

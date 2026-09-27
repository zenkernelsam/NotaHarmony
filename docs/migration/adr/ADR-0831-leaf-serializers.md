# ADR-0831 — 叶级字段序列化器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `apb.Z` = qed 8B `{d:f32@0, c:f32@4}`（prep4,8+2f）；
  `fsi.b0` = vy7 16B `{f,c,d,e}`（prep4,16+4f）；
  `rh8.O` = qo5 8B `{site:u16,pad:u16=0,timestamp:u32}`；
  `rh8.b` = qo5 构造 {c()=site, d()=timestamp}。
- qo5=8B vs cxc=12B（site+pad+timestamp+index）两级位置
  标识分层。
- `fag.n0`→`o0`：k3a 六访问器；`j7j.c`：sw9={wa0 资产 +
  `D(8,n,4)` 结构向量（zwd.a 元素写器、负长守卫）}。
- `apb.h`/`fsi.f` = qed/vy7 值类构造。

## Harmony 决策

8B/12B 位置结构与 2f/4f 结构写已逐字节对齐（880+本阶段）；
k3a ↔ PageBackgroundModel；sw9 ↔ PDF 布局编码。

## Parity 状态

等价（叶级线格式闭合）。

## 验证

- `d02-leaf-serializers.mjs`：17/17 通过。
- 全量 Replay 与双 HAP 构建见 Phase 887 提交。

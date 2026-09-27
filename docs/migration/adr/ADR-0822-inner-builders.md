# ADR-0822 — `*0j`/`baj` 内层构造器与混合静态

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `u5j` = 参数归一化门面 → 内层构造器建表：
  i→`haj.a`(ln2)、s/t→`r0j.a`(ge8)、u→`v0j.b`(he8)、
  v→`x0j.a`(je8)、r→`o0j.a`(wd8)、f→`baj.a`(rl2)。
- 各 `*0j` 为混淆混合静态：仅一个方法属 ops 层，其余为
  Bundle/protobuf/Compose/协程无关静态。
- `baj.a` 21 参 + 掩码（bit18/19/20 → vy7/z4/z5 默认；
  u5j.f 传 2883584 = bit18+19+21，bit21 为省略参数序号）。
- `o0j.a`：xgb→`tmf(I)` 挂钟包装、list2 `rz1.i0` 防御拷贝、
  分段负长 `Got negative length` 置 null。
- `o0j.b/c/d` = 二进制补丁应用器（magic 0xD1FFD1FF、
  version 4、op 码 switch）——delta 格式表面，无上层调用点。

## Harmony 决策

编码器入参形态与内层构造器对应；tmf 包装（875）、块类型/
像素对齐派生默认均已对齐。补丁应用器无对应面，登记待查。

## Parity 状态

等价（ops 写侧）；补丁格式留档。

## 验证

- `d02-inner-builders.mjs`：27/27 通过。
- 全量 Replay 与双 HAP 构建见 Phase 878 提交。

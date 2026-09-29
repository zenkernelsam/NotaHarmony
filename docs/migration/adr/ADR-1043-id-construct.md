# ADR-1043：opId 构造管线 + 浮点打包

## 状态

已接受（Phase 1099）。

## 决策

- `rh8.b(i,s)` = opId 经真 FlatBuffers 写→`qo5.b` 绑 →
  `ybg.c` 校验→`dk4`/`c8d` 池回收。
- `rh8.a(f,f)` = 双 float 打包 long（空间键）。

## 依据

8B struct 写 + LITTLE_ENDIAN 绑 + 校验 + 池。

## 后果

Harmony id 构造走真实序列化+校验；builder 池化防分配抖动。

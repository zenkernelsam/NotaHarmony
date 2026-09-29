# Phase 1053 报告 — FlatBuffers 写入路径

## 范围

`zwd` serializer 注册表、`z0c(21)` map、`flatbuffers.a`
builder、`apb`/`ywd`/`yec` 序列化器。纯审计。

## 原版发现

- `zwd.a(xwd,builder)`：lazy Map KClass→wx4，命中调用、
  未注册 `rgc.b`+throw（fail-loud）。
- `z0c` case21：`mx7` map 逐类型 put；`ywd` 内联示例
  `t(4,20)→v×4→t(4,8)→v×2→w→r`。
- builder API：t=prep v=float w=int j=field k/l=buffer/
  string r=offset；`apb.Z(qed)`=写两 float struct。
- 读/写对偶确立：cee/xwd 读 ↔ zwd/a 写。

## Harmony 决策

注册表分派+builder 等价封装。

## 产出

- 证据：`phase-1053-fb-write-path.md`
- Fixture：`d02-fb-write-path.mjs`（11/11）
- ADR-0997；全量 Replay 见本提交。

# ADR-0904 — `nz3`/`fa2.w`/`wj9`/`qub.l` 残余助手

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `nz3` = Kotlin EnumEntries；`uq9.m` payloadType 解码 =
  byte→相对序数 + 越界回退 entries[0]=NONE。
- `fa2.w` = `"Got negative length"` 日志（`a.c(yn7,str,exc,lg5)`）。
- `wj9` = R8 归并 Function1 元素提供器：case9=`qub.l`、
  case10=`f2c.l`、case7=`zgb.m`——就地初始化池化持有者。
- `qub.l(i,cxc)` = 零拷贝元素访问器：`i*12+f(slot)`→`cxc.b`，
  空向量 `h34.l` 越界；toString 实证 RemoveChars+lv2.N。

## Harmony 决策

就地初始化模式可按需复刻；unknown→NONE 回退已覆盖。

## Parity 状态

等价。

## 验证

- `d02-nz3-fa2-wj9.mjs`：15/15 通过。
- 全量 Replay 833 文件绿，见 Phase 960 提交。

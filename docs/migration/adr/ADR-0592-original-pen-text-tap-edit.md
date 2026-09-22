# ADR-0592 — TEXT 面裸笔点按文本块直接编辑（zl2 case25）

- 状态：Accepted
- Phase 623；对齐 `zl2.java` case25 + `xtc.c` + `tl7.w` +
  `dl1` z3 压制门（decompiled_1.0.3）。

## 背景

原版 TEXT 面点按分发（`zl2` case25）：`xtc.c`（xhe 过滤命中）
命中文本元素 → `qke` 直接编辑会话；命中含链接行（`tl7.w`）→
吞掉；落空 → `oke.a`。该路径在裸笔点按时生效——`dl1` 的
`z && !elh.h` 把选区命中压制为 utc，落空交还文本手势面。

Harmony 旧实现：DEFAULT（文本面）裸笔点按跳过选区分发后直接
落入双击计时器——已存在文本块也要双击才进入编辑，与原版
单笔 `qke` 直接编辑不一致。

## 决策

1. `stylusSuppress` 分支（双击计时器之前）做 xhe 等价命中：
   顶层优先 `pointHitsTextBlock` 循环——
   - 命中且 `linkHitOnTextBlock == null` → `lastTapTime=0` +
     `beginTextEditingAt` 直接编辑（`qke`/`uke.d` 等价）。
   - 命中但链接行命中 → 吞掉 return（`tl7.w` 等价）。
   - 未命中 → 保持双击创建路径（`oke.a` 落空吞掉的移植等价；
     原版经其他手势面创建文本框）。
2. 手指点按仍经 `!stylusSuppress` 选区分发（vtc 选中），
   不经此支——原版 `elh.h` 允许手指走选区命中。

## 边界 / fail-closed

- `elh.h` 的 `function0()` 位（手指输入开关/防掌触设置）在
  Harmony 无对应设置项——`stylusSuppress` 按 SourceTool 近似，
  已在此前阶段注释注册。
- `qke`/`oke`/`uke` 会话生命周期内部（挂起会话恢复光标等）
  已由 `beginTextEditingAt` 既有实现覆盖（suspendedCaretByBlock）。

## 证据

- `docs/migration/evidence/original-pen-text-tap-edit-2026-09-28.md`
- Replay：`d02-original-pen-text-tap-edit.mjs`（11 断言）

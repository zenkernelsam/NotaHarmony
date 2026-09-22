# Phase 614 — 复制/剪切对含锁定成员的 Group 弃组不散件（lg2.c）

## 原版证据

- `lg2.java:107-168`（`g`）：复制负载 = `jrh.a` 过滤后的 `h()`
  扁平 id 集 + `arrayList3`（解析成功的组 id）；`iterableL0` 为
  选中 `cqc` 组（`ftc.m`/`gtc` 自身），逐组 `c()` 解析；
  `arrayList5` 只留成功组 → `cg2` 组清单 → 粘贴恢复组。
- `lg2.java:51-105`（`c`）：递归解析——`set`/`resolved` 命中 →
  true；`failed` → false；`tl7.v` 取组后遍历 `M()` 成员，任一
  递归失败则整组 `failed`。锁定成员不在 `set` 且非组 → false →
  **整组弃件**，但其余未锁成员仍在 `set` 中散件复制。
- `itc.java`/`gtc.java`：`ktc` 三集语义——`h()` 扁平成员集
  （gtc 为 `b`）、`f()`（gtc 为 `qw3` 空集）、`c()`；
  `lg2.g` 的 `h()` 过滤天然覆盖组成员。

## 排查结论

Phase 610 只把锁过滤搬进扁平 id；`selectedGroupIds` 原样进
`prepareCopy`。`copyOriginalGroupGraph` 对成员不在
`copiedLeafIds` 的组返回 null → `prepareCopy` null → COPY
不写剪贴板、CUT 整单静默失败——比原版（仅弃组、散件照常）
更严，用户可见行为分叉。

## 修复

`NoteCanvasView.ets`：`ClipboardSelectionIdSet` 增 `groupIds`；
`clipboardSelectionWithoutLocked` 增选中组入参并调
`copyResolvableGroupIds`（lg2.c 等价递归：kept/resolved → true，
failed/visiting/非组/空成员 → false，成员全过 → resolved）；
COPY 与 CUT 的负载组清单均改用 `kept.groupIds`。DUPLICATE
保持原始 `dhb` case4 路径不过滤。

## 验证

- 新增 replay `d02-original-clipboard-group-resolve.mjs`：17/17 绿。
- 全量 desktop replay 套件：504/504 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。

## 提交

`Phase 614: copy/cut drop groups with filtered-out members (lg2.c)`

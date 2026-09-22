# Phase 623 — TEXT 面裸笔点按文本块直接编辑（zl2 case25）

## 原版证据

- `zl2.java` case25（191-211）：TEXT 面点按——`xtcVar.c(jE)`
  （xhe 过滤命中）命中 → `qke(qo5)` 直接编辑；未命中且
  `tl7.w(page,y)`（含链接行）→ `return null` 吞掉；否则
  `oke.a` 落空。
- `xtc.java:76`：`c(j)` = vnd 命中过滤 `instanceof xhe`。
- `tl7.java:823`：`w` = y 处文本行含链接内容 → true。
- `dl1.java:87`：`z && !elh.h`（裸笔无桶键）→ `z3=false` 压制
  rtc/vtc，落空交还文本手势面。

## 排查结论

Harmony DEFAULT（文本面）裸笔点按：`stylusSuppress` 跳过选区
分发后直接落入双击计时器——已存在文本块也需第二击才编辑，
与原版单笔 `qke` 直接编辑不一致。

## 修复

`stylusSuppress` 分支（双击计时器前）做 xhe 等价命中：顶层
优先 `pointHitsTextBlock` 循环——命中无链接 → `lastTapTime=0`
+ `beginTextEditingAt` 直接编辑；命中链接行 → 吞掉；未命中 →
双击创建路径不变。手指点按仍经 `!stylusSuppress` 选区分发。

## 验证

- 新增 replay `d02-original-pen-text-tap-edit.mjs`：11/11 绿。
- text-surface-dispatch / selection-tap-clear /
  recent-interaction-menu-gate 关联 fixture 全绿。
- 全量 desktop replay 套件：513/513 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

Phase 623 commit（见 git log）。

# Phase 1361 中文报告 — `untitled_note` 语义纠正 + string.json 格式还原

## 概述

本 Phase 纠正两类在 Phase 1358–1360 中引入的问题，均为**复刻保真**层面的实质修正。

## 一、`untitled_note` 值纠正（撤销 1358 的误判）

1358 依据 `app__shortcut_untitled_note`=`"Untitled"` 把 `untitled_note` 改成 `"Untitled"`。
本次深读原版源码确认这是末段名碰撞：

| 原版键 | 值 | 用途 |
|--------|----|------|
| `app__shortcut_untitled_note` | Untitled | 仅 `v50` 的 `ShortcutManager` 应用快捷方式标签 |
| `data_library_state__default_note_title` | New Note | `e5j.h` 空标题回退，`bib/e5j/id7/ksh/nti/y5j` 卡片/列表均用 |
| `feature_note__default_title` | New Note | 新建笔记默认标题 |

Harmony `untitled_note` 的 8 个调用点全部是笔记标题回退（库卡片、编辑器、导入、
最近删除、部件卡），**没有**应用快捷方式场景。故正确值=`"New Note"`（`default_note_title`
语义），已还原；zh `未命名`→`新笔记`。

> 原文卡片确实对空标题显示 "New Note"，而非 "Untitled"——1358 的改动方向反了，
> 本次予以纠正。

## 二、string.json 格式还原（撤销 reserialize 副作用）

1358–1360 用 `JSON.stringify(...,2)` 整体重写，把原**混排**格式（单行/多行并存）
规范成统一多行，破坏了 126 个按单行文本模式断言的 Replay。已改为格式保留式注入：
以 `4549008a` 原文为底，仅把正确值按各条目原有行形写回。净 diff 只剩 `"value"` 行。

## 验证

- `d02-untitled-format-restore.mjs`：**10/10**（新增格式守卫断言，防再次整体重写）。
- 全部 126 个引用 `string.json` 的 Replay 复绿。
- 已更 fixture（`d02-ui-wording-fix`/`d02-string-diffs`）断言同步纠正为新语义。

## 结论

30 处措辞修正全部保留且格式无损；`untitled_note` 回归原版 `default_note_title`
语义。教训：改资源/源码须**最小 diff**，禁止用 `JSON.stringify` 对带既有排版的文件
做整体重写；同名键须核**完整键名 + 调用点**双重确认再改。

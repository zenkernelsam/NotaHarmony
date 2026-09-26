# ADR-0785 — `core/` 包叶子面归档

- 状态：已接受（含一项差异登记）
- 证据：`docs/migration/evidence/phase-841-core-package.md`
- 回放：`docs/migration/replays/d02-core-package.mjs`（18/18）

## 决定

1. **9 个类型化异常族**归档（network×3、retrofit、analytics、
   logging×2、memory、model）——与 840 synced 族同型，
   原版错误面重度类型化。
2. **`SharedMemoryByteArena`**——原生墨水共享内存区归档；
   Harmony 渲染栈不暴露该抽象，登记。
3. **`libglmath` 本地数学引擎**（init/measure/draw/searchText
   四 JNI）：原版 LaTeX 由 native 排版+绘制+可搜索；
   Harmony `MathEditorOverlay` 走 `PixelMap` 位图预览路径——
   **登记差异**（native 排版不可移植；位图化保持外观语义）。
4. `UserDataStoreInitializer`/`core/model/snapshot/` 归
   819/839 既有登记。

## 后果

`core/` 包闭合；数学渲染差异有了正式锚点（位图预览 vs
native 排版引擎）。

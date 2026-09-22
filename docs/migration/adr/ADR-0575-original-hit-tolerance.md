# ADR-0575 — 元素命中两程 ±5 容差（fu1.e）

- 状态：Accepted
- Phase 606；对齐 `fu1.e`/`fu1.g`/`xtc.b`（decompiled_1.0.3）。

## 背景

原版 `fu1.e` 是所有点按探测（`xtc.a`/`xtc.c`，进而 vtc/ttc/tape）
的统一命中入口：**先精确点查询，落空再以 ±5 矩形 + 半径 5 查询圆
复测**，取 z 序最上。容差为**世界/page 单位**：`fu1.j` 按元素缩放
归一（`半径/maxScale`）后在元素本地判定（块半长 +fB、形状描边带
+ 查询圆、笔带宽 + 查询圆）。

Harmony `topmostPageElementIdAt` 只测精确点——点按落在元素边缘
5 单位内时原版能命中而 Harmony 判 miss（清选/落空套索），
细笔迹与小块边缘处差异可感知。

## 决策

1. `topmostPageElementIdAt` 拆两程：`hitOrderedElementIdAt(ordered,
   point, 0)` 精确 → 落空再 `…, 5)`。z 序遍历不变（tape 仍最上）。
2. 容差单位 = 世界/page 单位（`fu1.j` 缩放归一）：
   - 块：`expandLocalBounds(bounds, worldTol, transform)` 内以
     `worldTol/maximumLinearScale(transform)` 转本地后四边扩张
     （`gi3+fB` 等价）；
   - 笔：`brushWidth·widthFactor·scale/2 + worldTol`；
   - 形：`strokeWidth·scale/2 + worldTol`，填充内部命中不变。
   `hitStrokeAtPoint`/`pointHitsShape` 增加默认 0 的
   `worldTolerance` 参数，其他调用点语义不变。
3. `tapeIdsAtPoint`：精确收集为空 → 两程顶层命中若是 tape
   （`isTapeElementId`）→ 回退其单例（`xtc.b` setX1 空回退等价）。

## 偏差

- 原版第二程经 ±5 矩形宽相过滤再 `g()` 精判；Harmony 直接全元素
  容差精判（z 序同、结果同，仅省宽相）。
- `vh5(j,5)` 半径为世界单位，与 Harmony 画布单位制等价。初版实现
  误按元素本地单位处理（已按 `fu1.j` 缩放归一证据修正）。

## 验证

- `d02-original-hit-tolerance.mjs`：13 断言（两程次序、各类容差
  传递、世界单位缩放归一扩张、tape 精确收集→顶层回退）。
- `d02-original-selection-tap-clear`/`d02-original-tape-tap-reveal`
  已随签名演进更新。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。

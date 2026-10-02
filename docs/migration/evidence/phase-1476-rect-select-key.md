# Phase 1476 — Ctrl+Shift+T 视口中心矩形选区（f2:230-238）

## 原版证据（decompiled_1.4.2）

### 键码

`pa8.java`：`pa8.G = ofk.e(48)` = Android `KEYCODE_T`
（Harmony `KEYCODE_T = 2036`，SDK `keyCode.d.ts` 核实）。

### 分发支（`f2.java:230-238`，`!rsi` 门内、`!pa8.W` 块内）

```
230  if (pa8.a(db8.n(keyEventB), pa8.G)) {                 // T
231    if (lxm.a(db8.o(keyEventB), 1)                       // KeyUp
          && u7b.g 键盘使能旗
          && !bd8.U.r) {                                  // !c5i isEffectivelyEnabled
232      long jC = ((exj) jxjVar.e.F.getValue()).c();      // 视口中心
233      ome omeVar = bd8Var4.L;
234      sbe sbeVar2 = new sbe(cx-120, cy-60, cx+120, cy+60);
235      omeVar.a();                                      // 清选
236      omeVar.g.l(null, new u64(sbeVar2));               // 矩形选区请求
    }
  }
```

- `exj.c()`：`jxjVar.e` 视口矩形对象 `.c()` = 中心点（打包 long →
  `s64.e/f` 拆 x/y），画布坐标。
- `sbe(cx-120, cy-60, cx+120, cy+60)`：**240×120 画布单位**矩形，
  中心=当前视口中心。
- `ome.a()` = `m=null` + `a.g(null)` 清当前选区（`ome.java:38`）。
- `ome.g`/`i` = `ptg<u64>` 状态槽（`qtg.a(null)`）——发布矩形
  选区请求。
- 链序：Ctrl+D(221) → **Ctrl+Shift+T(230)** → M(240) → I(244) →
  DEL(247)；支内无 `b2=0` → DOWN 亦消费。

### 消费端

- `ch1.java:55-68`：拖拽矩形完成路径在 `z3` 旗成立时同走
  `omeVar.a()` + `ome.g.l(null, new u64(sbeVar))`——键盘支与拖矩形
  共用同一请求通道。
- `r3b.java:27` `c(sbe, msf)` → `p3b` 协程：矩形相交命中选区
  （`u64` 负载即 sbe 矩形）。

### 门控

- `bd8.U` = `c5i` 实例（`bd8.java:27/64`，`vd7.java:96` 构造）。
- `c5i.r` = "isEffectivelyEnabled" 派生 `r3e`（`c5i.java:63-64`：
  `q`(非空 bool 旗) + `i`(用户覆写) 合成）。Ctrl+Shift+T 仅在
  `!U.r`（该使能关闭）时触发——判定该派生旗对应选区类功能的
  有效使能；Harmony 无对应切换对象，按恒放行近似（登记差异）。
- `u7b.g` 键盘使能旗默认 true（P1468/1475 同例登记）。

## Harmony 移植

- `OriginalKeyboardChords.ets`：`ORIGIN_KEYCODE_T = 2036` +
  符号对照注释。
- `NoteCanvasView`：
  - 分发支（`!textEditing` 块内、DPAD nudge 后、M/I 支前）：
    `ctrl && shift && KEYCODE_T` → UP 调
    `applyKeyboardRectSelection()`，无条件消费。
  - `applyKeyboardRectSelection()`：
    `viewport.screenToCanvas(canvasW/2, canvasH/2)` = `exj.c()`
    视口中心（画布坐标）；`beginSelection(RECTANGLE, (cx-120,
    cy-60))`（重置 id 集 ≡ `ome.a()` 清选）；`updateSelection
    ((cx+120, cy+60))` 扩界；`finalizeSelection(...)` 全元素集 +
    `strokeIntersectsSelectionPath` lambda——与拖拽矩形完成路径
    同一命中核（`rectIntersects`/`selectionPath`）；零命中 →
    `deselect()` + `selectionVisible=false`。

## 差异登记

- `bd8.U.r`（c5i isEffectivelyEnabled）未移植——Harmony 恒放行
  （登记差异；该旗关闭时原版才允许 T 支，开启场景未等价）。
- `u7b.g` 恒真近似（同 P1468/1475）。
- `ome.g` 请求通道（异步 ptg 槽 + 协程消费）→ 同步直调同一
  矩形命中核，语义等价。

## Replay

`docs/migration/replays/d02-original-rect-select-key.mjs`（21 checks）。

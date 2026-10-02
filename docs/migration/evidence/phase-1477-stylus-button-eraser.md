# Phase 1477 — 手写笔杆键擦除切换（bd8.B 尾支）→ fail-closed

## 原版证据（decompiled_1.4.2）

### 键码集

`bd8.java:46`：

```
k0 = oag.y2(pa8(ofk.e(308)), pa8(ofk.e(309)),
            pa8(ofk.e(310)), pa8(ofk.e(311)))
```

Android `KeyEvent`（AOSP 核实）：

- 308 = `KEYCODE_STYLUS_BUTTON_PRIMARY`
- 309 = `KEYCODE_STYLUS_BUTTON_SECONDARY`
- 310 = `KEYCODE_STYLUS_BUTTON_TERTIARY`
- 311 = `KEYCODE_STYLUS_BUTTON_TAIL`

即**手写笔杆全部四个侧键**。

### 分发支（`bd8.java:208-215`，`B()` 第一遍分发器尾）

```
if (!k0.contains(n) || ctrl || alt || shift || !G())
    return null;                        // 不接管 → 进 f2 兜底链
if (lxm.a(db8.o(keyEvent), 1))          // KeyUp
    D();
return Boolean.TRUE;                    // 命中即消费
```

- `G()`（`bd8:257`）= `h45.b(h35.q0)` 特性旗——
  `h35.java:266`：`q0 = "STYLUS_BUTTON_ERASER_TOGGLE"`
  （td5 日期门 `LocalDate.of(2026,9,3)` 起生效）；
  附加排除 `k24.a() && h35.L`。
- 无任何修饰键才接管（ctrl/alt/shift 皆须否）。

### `D()`（`bd8.java:226-244`）防抖切换

```
o5h = this.g0;                          // g0 = new o5h()（bd8:63）
z = o5h.c;                              // 当前"笔键擦除"激活态
if (z || (d != null && age(d) < 100ms)) {   // o5h.e = 100ms
    if (o5h.c) { o5h.c = false; o5h.d = now(); }
    return;                              // 解除后 100ms 内重按抑制
}
if (b == null || age(b) >= 100ms) {
    o5h.b = now();
    this.S.a.f(fxi.a);                   // → hxi 通道发 ToggleEraser
}
```

`o5h` 字段：`e`=100ms 防抖窗、`a`=`gli.a` 时钟源、`b`=上次
激活时间戳、`c`=笔键擦除激活旗、`d`=上次解除时间戳。

### 消费端

- `fxi.java`：`gxi` 事件单例，`toString()="ToggleEraser"`。
- `npb.java:53-72`：`fxi` → `f6n.e(vti)` 取擦除工具 id → 在
  当前页工具列表（`sti.c.e + sti.d.e` 合流）按 id 找 `wsi` →
  `xqbVar.B(wsi)` **选中擦除工具**。
- `qxi`（色/宽井通道）对 `fxi` 透传不处理。

## Harmony 现状

- OpenHarmony `keyCode.d.ts` 全枚举无 `KEYCODE_STYLUS_*`——
  笔杆键不进入 `KeyEvent` 通道；
- `touchEvent.d.ts` 的 `SourceType.STYLUS`/`ToolType.PEN` 只含
  来源/工具类型，**无 button 字段**；
- `ArkUIStylusAdapter.ets` 无按键处理路径；
- 真机行为不可静态确认（M-Pencil 侧键或由系统手势策略消费）。

## 结论

**fail-closed**：无公共 API 通道即不移植。登记差异并钉死：
未来若 Harmony 暴露笔杆键事件（任何通道），语义目标 =
`npb` 路径——按 `f6n.e` 擦除工具 id 选工具，带 o5h 100ms
按下/解除防抖。

# 原版 Canvas 状态恢复与有限 zoom 证据（JADX / Harmony SDK，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/c5g.java`：
  `FB97DAD2C6E3AA284C20EFCB9017FCC7C064254EE71B3C61DD52E2CFBBE73571`
- `sources/defpackage/v0g.java`：
  `A58895AB0CDAC64A1EB62C3B25DCA72D99DC6A3D03121FC9F7065505670FE3EC`
- `sources/defpackage/zea.java`：
  `100A9F2F66A86BE4265A5FC105B9053AA5AB75DA069ABF9AEA8BAE0A109CF39A`
- Harmony SDK：`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\component\canvas.d.ts`
  - SHA-256：`64FA310903D354A64B211AAFB2A4B53D89DE5D9813CD01838F89E1F23D6451F4`

## 原版绘制状态事务

### `c5g.java:143-155`

Pencil splat 路径先保存 Canvas，应用 viewport 后调用 `zea.h()`；无论内部是否异常，`finally` 都执行
`canvas.restoreToCount(iSave)`。这证明原版不允许 splat renderer 把 viewport/paint 相关状态泄漏给后续元素。

### `c5g.java:166-205`

retained bitmap 与追加列表路径有外层 save；bitmap 的 translate/scale/draw 又有独立内层 save。反编译器把
部分 `finally` 还原成 success/catch 两条显式 `restoreToCount`，但两条出口都恢复保存深度后才返回或重抛。
这与 Kotlin/Java 的异常安全语义一致，不能只照搬成功路径的最后一行 restore。

### `c5g.java:254-265`

普通 path 绘制在 `try/finally` 中调用 `d(canvas)` 和 `drawPath/l96.l0`，随后恢复 `iSave`。因此 path、mask
或 blend helper 抛错时也不能留下 transform/clip。

### `c5g.java:272-285`

Tape renderer 调用 `qfe.a()`；正常路径和 `catch(Throwable)` 都先 `restoreToCount(iSave)`，异常再原样抛出。
原版选择“恢复状态但不吞错”，Phase 258 保持同一原则。

## 原版 zoom 数据边界

`v0g.java:75-89` 恢复持久化 viewport zoom 前先用 `Math.abs(value) <= Float.MAX_VALUE` 排除 NaN/Infinity，
再要求范围位于 `[0.25, 10]`；否则记录 `Discarding corrupt persisted viewport zoom`。Harmony 当前 viewport
已有等价有限值门。`DirtyRectTracker` 虽是移植侧优化组件，也必须保持同一有限 zoom 前提，不能让
`+Infinity` 通过 `zoom > 0` 后把抗锯齿 padding 降为 0。

## Harmony Canvas 契约

`canvas.d.ts:4347-4370` 将 `restore()` 定义为弹出 drawing state stack 顶部状态；`4372-4401` 将 `save()`
定义为把当前绘制状态压入该栈。由此可知，异常漏掉一次 restore 不是局部变量问题，而是会把状态栈深度及
transform/clip 等配置带入下一次绘制。

## 移植结论

- 所有生产 renderer 的每个 `save()` 必须有同层 `finally restore()`，不能只依赖最外层 `renderFrame` 恢复一次。
- 异常继续传播；本阶段不新增静默 fallback，也不掩盖坏资源或坏路径。
- retained bitmap/multi-dirty 架构无需重做；本阶段补的是异常路径状态所有权和此前遗漏的非有限 zoom。
- 真实设备的 500 笔帧时、长时内存与像素边缘仍需设备验收。

# 原版缩略图 Bitmap / onDiskOpId 配对与新鲜度门禁证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/cn7.java`：
  `66A3D97A54737B56B51D4D6D7FF4CBE1A13FFDB017B31F1D37CCA804E505ED79`
- `sources/defpackage/if9.java`：
  `A85D2FAC930471914096073CA8E48C767C8152BFE1DB250A8EF76E94653FEEE7`
- `sources/defpackage/h59.java`：
  `DB71C2DF5B5F0D9F30B7AF9202FC7970A031EA73BA65311D21785895BBC93FF7`
- `sources/defpackage/m6j.java`：
  `6A5AC6238AF0C0FC6F5B80C2AA84E3B6116C01D42015188D26393510D9158BF1`

`m6j` 的普通 JADX 输出包含重复 Compose 分支，并把一处 null 判断反编译成不可执行的组合条件。为避免按坏的
Java 表达式猜语义，本轮同时使用 JADX 1.5.6 simple control-flow 输出复核；当次输出 SHA-256 为
`2EA5A6FF5507FDF1FFE1E8BE75FF72803F5464BC284C5E175CB5AF51F3300D5F`。下文结论同时受普通输出中的字段读取/
比较调用和 simple 输出的跳转关系约束。

## 1. 原版把 Bitmap 与落盘 operation identity 作为同一状态的两半

`cn7.java:8-24` 持有两个 map，`toString()` 明确命名为：

```text
LocalThumbnailState(bitmaps=..., onDiskOpIds=...)
```

`if9.java:5-13/32` 则把单篇笔记投影成：

```text
NoteThumbnailData(bitmap=..., onDiskOpId=...)
```

这不是“一个 bitmap cache 加一份无关 metadata”；原版 UI 判断缩略图能否展示时必须同时消费这两个字段。

## 2. 两个 map 按同一个 note identity 成对投影

`h59.java:88-91` 对同一个 `ttfVar` 分别读取 `cn7Var.a` 与 `cn7Var.b`，随后构造同一个 `if9`：

```java
new if9(
    (tr) s2d.g(ttfVar, cn7Var.a),
    (qo5) s2d.g(ttfVar, cn7Var.b)
)
```

因此 bitmap 不能脱离其生成时对应的落盘 operation identity 单独发布。

## 3. 原版只展示不落后于调用方期望 identity 的 Bitmap

`m6j.java:157-166` 读取 `NoteThumbnailData.onDiskOpId`，调用 `so5.a(produced, expected)`，然后只有 validity
成立才读取 bitmap。普通 JADX 在 null 条件上产生坏表达式，但 simple control-flow `L77-L88` 给出的实际跳转为：

```text
produced onDiskOpId == null                  -> invalid
expected onDiskOpId == null                  -> valid
compare(produced, expected) < 0              -> invalid
otherwise                                    -> valid
valid                                        -> read bitmap
invalid                                      -> bitmap = null
```

也就是：已生成缩略图没有 source identity 时不能展示；调用方有期望 opId 时，落后的 bitmap 必须隐藏；只有
identity 足够新时才把 bitmap 交给 UI。原版在 bitmap 暂时无效时显示占位/加载状态，而不是继续展示已知过期图。

## 4. Harmony 等价 identity 不能直接照搬 qo5 比较器

Harmony 当前没有原版 `qo5` 的可比较 operation id 流，而是通过 `getFirstPageThumbnailState()` 取得：

- 首页 `pageId`；
- 页面尺寸、方向、背景/fallback；
- 单调 `content_revision` 与 element count；
- 主题纸色/线色；
- note asset generation。

这些字段组成一次渲染的 source revision。这里不能对拼接字符串做 `>=` 或字典序比较；正确适配是对同一次
render attempt 要求 pageId 与完整 revision **精确相同**。任一字段变化都表示刚生成的 PixelMap 已落后，必须释放并
针对新 source 重试。精确相等是 Harmony 当前 revision 模型下对原版“不得展示落后 bitmap”的保守等价。

## 5. 本轮确认的旧 Harmony 竞态

旧 `LibraryPage` 的顺序为：

```text
读取首页 revision -> 异步加载元素/资产并渲染 -> 直接把 PixelMap 与旧 revision 写入新缓存
```

页面内容、首页身份或资产 generation 在渲染期间变化时，旧实现不会重新读取 source，因而可能把混合内容的
PixelMap 错配到旧 revision。渲染失败时又无条件保留旧 PixelMap，即使旧 revision 已被证明落后；这与原版
`m6j` 的 validity gate 相反。

## 移植结论

- 每次 render 前后都读取首页/source identity；只有 pageId 与完整 revision 未变才成对发布 PixelMap/revision。
- source 变化时先释放未发布 PixelMap，再使用最新 source 有界重试；不得无限追逐持续写入页面。
- generation、页面 lifecycle 与 renderer identity 仍是外层门禁，不能被 source revision 检查替代。
- 异常时只允许保留“再次证明仍是当前 source、且 cache revision 完全相同”的旧图；否则使用占位。
- 所有未发布、被替换和页面退出的 PixelMap release 都要捕获异步失败，避免清理异常变成未处理 rejection。

## 验证边界

静态 fixture/replay 能证明配对发布、两次 source 读取、有界重试、失败隐藏和释放路径；仍需设备验证编辑首页后
返回资料库、快速同步/切换文件夹、100 篇滚动时的像素一致性、占位闪烁与真实 native PixelMap 峰值。

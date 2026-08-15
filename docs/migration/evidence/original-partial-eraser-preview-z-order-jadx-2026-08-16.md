# 原版 Partial Eraser transient preview z-order：JADX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 主反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- 日期：2026-08-16

本证据补充
`original-partial-eraser-transient-preview-jadx-2026-08-16.md`。前一份证据已经证明 tool-5 Ink 是
transient interaction；本文件继续回答它在页面内容中的真实绘制层级，纠正“普通 Stroke→Text 页面应把 Text
无条件重画到 preview 前景”的错误推断。

## 1. transient CREATE_INK 使用当前 operation clientTime

`kt1.d()` 在 `d04.J` 分支选择 `u16.PARTIAL_ERASER`，`bt1.java:36-46` 再把 payload 作为 transient
CREATE_INK 派发：

```java
kt1Var.l = xq9Var.a(new wq9((dm2) obj6, null, true, (xgb) obj5, 10));
```

本地 transaction 入口 `n1d.java:170` 把当前毫秒时间传给 `fsi.s(...)`：

```java
fsi.s(tzcVar.P, tzcVar.Q, System.currentTimeMillis(), ix4Var2)
```

`fsi.java:1756-1765` 用该 `j` 创建 `xq9`，而 `xq9.a()` 最终把 `this.e` 交给 `zq9.e(...)` 的
`clientTime` 字段：

```java
ix4Var.invoke(new xq9(bs1Var2, bs1Var, arrayList, aVar, j));
...
zq9.e(this.d, qo5VarB, ceeVar, this.e, null, ..., sdfVar)
```

所以这条 transient Ink 的默认层级时钟就是本次新 operation 的 clientTime。录音期间 `u5j.g()` 还可把同一
Realtime/audio clock 写入 Ink payload；这不是固定常量，而是与创建时刻同步的显式层级时钟。

## 2. Ink 的 `g()` 就是排序所用 z-index

`s06.java:489-496`：若没有 MODIFY_INK 的 z-index register，Ink 优先使用 CREATE_INK payload 的显式
Realtime；否则回退到 CREATE operation 的 clientTime：

```java
public final long g() {
    ...
    tmf tmfVarB = this.c.B();
    return tmfVarB != null ? tmfVarB.I : this.b.k();
}
```

tool-5 不是 Highlighter；`s06.e()` 只有 `u16.HIGHLIGHTER` 才返回 `true`。因此 partial eraser 属于普通
z-index 内容，而不是固定的 bottom-highlight pass。

## 3. 页面实体按 z-index 升序，最新 transient Ink 位于既有内容之后

`vnd.compareTo()` 先处理 Tape 与 Group layering；普通实体最终通过 `ly3.g()` 比较。`vnd.java:24-37` 的
`c(...)` 对两个 unsigned long 返回升序结果，时间更小的实体排在前面，时间更大的排在后面；相同时间才按实体
ID 稳定打破平局。

`aa6.java:2001-2054` 把页面内容分为 bottom-highlight 与普通列表，并对两者分别调用：

```java
eu1.J0(arrayList);
eu1.J0(arrayList2);
return new uld(arrayList2, arrayList);
```

`eu1.J0()` 使用 `Collections.sort(list)`，所以普通列表按 `vnd.compareTo()` 升序。新手势的 clientTime 晚于
页面中已经存在的 Text/Image/Math/Shape/Ink，tool-5 preview 因而排在这些既有实体之后。

## 4. 原版 tile renderer 的普通列表并非只有 Ink

普通 `aeg.java` 因 JADX SSA/ConstructorVisitor 失败缺失 `invokeSuspend()`；沿用 2026-08-15 已生成的 JADX
fallback 线性输出：

- 文件：`%TEMP%\nota-aeg-fallback-20260815.java`
- SHA-256：`1B1741F399CE8298FCA6A39E9094C86CC4A6F6D89E88E85F5469FD629AE6A578`

fallback 约 `930-995` 把同一有序实体流分类为：

```text
s06  -> Ink
m4d  -> Shape
hp5  -> Image
xhe  -> Text
r08  -> Math
```

随后它把 `uld.a` 与 `uld.b` 合并，约 `1558` 起逐个迭代 `vnd.I`，为不同实体生成交错 draw command；普通
Ink pass 约 `1065-1112` 使用 `BlendMode.SRC_OVER`。因此 renderer 没有“先把全部 Ink 擦完，再永远把 Text
盖回前景”的固定分层。tool-5 是这个统一内容序列中最新的 Ink，会覆盖它之前绘制的 Text/Image/Math/Shape；只有
在它之后的内容才会保留在上方。

## 5. 对 Harmony 的直接约束

1. preview 必须留在 durable `elementOrder` 之外，但渲染物化时必须临时追加为最后一个 Stroke。
2. preview 的 destination-out 只能作用于透明内容层，不能直接挖穿 Paper/background。
3. dirty crop 内必须重建完整有序内容，再在最后绘制 preview；不能只裁 completed handwriting bitmap，也不能
   无条件重画 Text 为前景。
4. 这一结论同时适用于常见 Stroke→Text 页面和 mixed Stroke/Text/Shape/Image/Math 页面。

## 文件 SHA-256

- `kt1.java`：`815C902D4F4F34CCBD993BAFD5A90577302C8CB669CBBFDC512CD3AD4E77CFF3`
- `bt1.java`：`A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA`
- `xq9.java`：`93586BC43AA1C22B9AEE0C69329A77F946A1D24A414D9E73479E66BBD3CA7176`
- `fsi.java`：`CC752CA8DB4092E7A44E650AF134FD218B153BF1958A6E839D85DF478E95FAC7`
- `n1d.java`：`62FE986003DD014A7F18BF69A19353D301C24F5A89A27DFFD9C3FD99198AF096`
- `s06.java`：`A6E7B7F3D0EEAE1B898CEE66E5AD56C55DEC50681CC3D3DB6E059CF5E7CADC19`
- `vnd.java`：`06B9601160515A05EE55C8903C9F0A72E94CDBB742D5B239D8A3D353E46747CB`
- `aa6.java`：`43CF447B474BBE01F0AD53C4342214818C5D89AE2CDFDEFBAA9D6A3D0676CEA5`
- 普通 `aeg.java`：`C00E782664D56A0C6638C33AA714A7656A9E010B3F8C6DA23A757274783B7742`

## 尚需设备验证

本阶段可由静态证据闭环排序与合成结构，但未启动设备、模拟器或 Hypium。真机仍需观察 Text/Image/Math
交叉路径、PDF/深色纸张、快速长路径、400% zoom、超大页面 crop transfer 与内存峰值。

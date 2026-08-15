# 原版本地笔记背景 `SET_METADATA` 出站：JADX 与 DEX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- DEX 复核：Android SDK `apkanalyzer dex code --class vnf`
- 日期：2026-08-16

本证据回答本地纸张尺寸、模板和方向应写入哪个原版 operation，完整 FlatBuffer 如何编码，以及 Undo 为何必须
保留 nullable `pageBackgroundRegister`，不能只恢复一个视觉等价的具体 Letter 背景。

## 1. 设置面板写的是笔记级 `SET_METADATA`

`uge.java:139-142` 的纸张交互把 `l3a.a(...)` 生成的 `nz9 PageBackground` 包进 `qgh.b(...)`。有活动笔记时，
该 `m2d SetPageBackground` 再作为第二个参数传入 `u5j.H()`：

```java
u5j.H(x09Var, null,
  qgh.b(l3a.a((l3a) vgeVar.R.getValue(), null, ((a79) x09Var).K, 3)),
  null, null, null, null, null, null)
```

`u5j.java:245-248` 只把参数转交 `xj2.d()`；`xj2.java:168-189` 的 writer `K()` 将 `m2d` 写入
八字段 `l2d SetMetadata` 的 field 1。`xj2.java:700-736` 建立并返回完整 `l2d` table。因此普通纸张 UI 不是
`MODIFY_PAGE.background`，而是 payload type 1 `SET_METADATA.pageBackground`。

## 2. present wrapper + null value 是明确的重置操作

`qgh.java:71-85` 即使输入 `nz9Var == null`，仍建立一个一字段的 `m2d` table：

```java
int iL = nz9Var != null ? vv7.L(nz9Var, aVarA) : 0;
aVarA.C(1);
aVarA.h(0, iL);
```

所以必须区分：

- `l2d.field1` 缺省：不修改笔记背景；
- `l2d.field1` 指向 `m2d`，但 `m2d.field0` 缺省：把 register 明确写成 null；
- `m2d.field0` 指向 `nz9`：写具体背景。

Harmony writer 必须保留这个三态；把 explicit-null wrapper 省掉会把“重置”错误变成“无操作”。

## 3. `nz9` 的完整 wire 形状

`vv7.java:378-402` 把 `nz9` 的五个字段交给 writer `M()`：

1. field 0：`k3a Paper`；
2. field 1：`sw9 PDFAsset`；
3. field 2：rotation float；
4. field 3：`qed sourceSize` inline struct；
5. field 4：`vy7 margins` inline struct。

`k3a.java` 进一步固定 paper 的 flair、spacing、bleeds、centered、64-bit color struct 与 legacy index；
`sw9.java` 固定 PDF metadata、layout behavior、total/consumed page count、offset 和 crop-box vector。因而本地 writer
不能只编码纸张枚举或宽高，也不能在改纸张时丢掉既有 PDF metadata、rotation 或 crop boxes。

## 4. 原版纸张换算、模板和保留规则

`l3a.java:27-74` 是设置面板到 `nz9` 的转换函数：

- imperial 尺寸乘 `72.0f`；metric A 系列乘 `2.83465f`；
- `h4a.e()` 根据 portrait/landscape 交换 source width/height；
- `c4a` 的可选纸张为 Letter、Legal、Tabloid、A3、A4、A5、A6、A7；具体尺寸见对应
  `e4a/d4a/f4a/x3a/y3a/z3a/a4a/b4a`；
- `jq0.a()` 把 Lines/Dots/Grid 映射为 `n3a` wire 值 0/1/2，Plain 为 null；
- `gq0` 默认 spacing 为 0.5 inch，乘 `m09.g == 72` 后为 36 pt；
- `flairBleeds` 为 `flair != LINES`；`fag.k(..., 64)` 使 `flairCentered=false`；
- `nz9.l()` 的 PDF 与 `nz9.m()` 的 rotation 被保留；
- margins 写为 `m09.d`，而 `a79.java:63-66` 证明它是四边各 36 pt。

因此 Harmony 纸张选择必须生成与上述 Float32 规则相同的 source size，保留 PDF/rotation，并把四边 margin
重设为 36 pt。

## 5. 方向选择看未旋转 source size

`fad.java:1113-1120` 从 `nz9.n()` 的 source width/height 直接决定 `w3a` portrait/landscape，没有读取
`nz9.m()` rotation：

```java
float fD = nz9Var.n() != null ? nz9Var.n().d() : 0.0f;
w3a w3aVar = fD > (nz9Var.n() != null ? nz9Var.n().c() : 0.0f)
  ? w3a.J : w3a.I;
```

所以设置面板方向与旋转后的可见宽高可以不同。Harmony 必须让 picker 显示 source orientation，同时仍用
rotation 后的宽高渲染页面。

## 6. reducer 写笔记级 LWW register

`v69.java:1161-1169` 读取 `l2d.p()`；wrapper 存在时，不论其 `j()` 返回具体 `nz9` 还是 null，都调用
`pageBackgroundRegister` 的 `fqb.c(operation, value)`。`fqb.java:23-30` 只在新 operation identity 严格更大时
替换 winner。背景是笔记级独立 LWW register，不是当前页物化列。

Harmony 本地出站必须先建立完整原版 operation，再调用现有生产 reducer；不能只更新 `page_info` 后补一条
上传日志，否则本地 winner、页面 fallback 与同步 payload 会分叉。

## 7. 原版 Undo 保留 exact-null register

JADX 无法结构化还原 `vnf.c()`，因此对 APK 本体执行：

```text
apkanalyzer dex code --class vnf com.gingerlabs.notability.apk
```

在 `SET_METADATA` 逆操作分支（smali 标签约 `:cond_fa5`）可见：

```text
invoke-virtual {v5}, Ll2d;->p()Lm2d;
if-eqz v1, :cond_fdc
... iget-object v1, v1, La79;->K:Lnz9;
invoke-static {v1}, Lqgh;->b(Lnz9;)Lm2d;
...
invoke-static/range {v19 .. v27}, Lu5j;->H(...)Ll2d;
```

即：原操作含 page-background setter 时，逆操作读取修改前模型快照的 `a79.K` 并再次调用 `qgh.b()`。若旧
register 是 null，逆操作就是 **present `m2d` + null value**，而不是一个具体 Letter `nz9`。

因此 Harmony durable history 必须同时保存：

- 供显示和页面物化使用的 effective background；
- 供下一条原版 operation 使用的 exact nullable register value。

只保存 effective Letter 会让 Undo 后视觉相同但 wire winner 不同，破坏后续同步与原版行为等价性。

## 8. 新页继承笔记 register

正常原版 `CREATE_PAGE` 可让 page background setter 缺省，页面级 register 保持 null，再通过笔记
`pageBackgroundRegister` 得到有效纸张。Harmony 本地新页因此应发送 background-null 的普通
`CREATE_PAGE`，由生产 reducer 按当前 note fallback 物化尺寸/模板；不能把笔记纸张复制成每页独立 winner。

该边界修正了 ADR-0082 早期把“无 note winner 时的 Letter fallback”泛化为“每个 A4 新页都要携带
page-level nz9”的结论。

## 文件 SHA-256

- `uge.java`：`96E682D67C3BFEEB0EDE7415C07706DA6222A606273DE9C45F980D9DE1BB7F60`
- `qgh.java`：`2431A774872F58C30B64FFA5EE2A90C82B29C24D349B5A4EBF3CDD1BF6785698`
- `u5j.java`：`F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC`
- `xj2.java`：`1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C`
- `l3a.java`：`93FD679009AB625DF12EAF39127211D6964E587747B725D0213A0075D5A04836`
- `fad.java`：`1C7F7E78A0AA7CF5E4602CE1418D0EEB92014F8DB8268AC427868D32AC74502B`
- `vv7.java`：`399795391A9D41AEF3FD4BCCA9FA4D6D34A9B660C7FDA751354AA0F6892693EF`
- `l2d.java`：`59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8`
- `m2d.java`：`0E25EEC73569C9618F08D5CF27A0C6DE32C5A2FEE1C576CFC4D64F4DA776E261`
- `nz9.java`：`2BBB2FF908D57E1C4F93B7E9B85A83C8B438CC8D7CEB1633D4931F7F5F1F0B3E`
- `k3a.java`：`C66842427EE7C6E509A0D73050774C950E21131F65064D3AED96A1FB1E7FAFF1C`
- `sw9.java`：`E75788C6CF06B78E1C14C216B5418209FCF0770C9220E1F3EE0432E097FC2357`
- `v69.java`：`69A28ACDF6B65139405E3F22B2EF42AC3DC8FF4E3D8054438EC54B745FE315EF`
- `vnf.java`：`076F6A267E50BA5565FDA4D6EDEFB8BDE9B05807A328C34D6B6C339E5BDCC157`

## 尚需设备验证

本阶段不启动设备、模拟器、虚拟机或 Hypium。真机需验证纸张切换、保留 PDF 的四种 rotation、连续
Undo/Redo、重开、同步后重新下载、新页继承、多端并发 SET_METADATA，以及设置面板方向和实际页面方向的显示。

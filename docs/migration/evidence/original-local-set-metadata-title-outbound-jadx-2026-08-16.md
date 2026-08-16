# 原版本地笔记标题 `SET_METADATA` 出站：JADX 与 DEX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- DEX 复核：Android SDK `apkanalyzer dex code --class vnf`
- 日期：2026-08-16

本证据回答标题编辑应写哪一种原版 operation、空标题与长度如何处理、title-only FlatBuffer 是否会修改背景，
以及 Undo/Redo 为什么必须再次生成新的原版 `SET_METADATA.title`。

## 1. 编辑期间最多保留 200 个 UTF-16 code units

`de4.java:27-52` 在标题输入值变化时调用 `lvd.b1(200, text)`；`lvd.java:354-364` 证明 `b1()` 最终是
Java `substring(0, i)`，因此上限按 Java `String.length()`，即 UTF-16 code units 计数，不是 UTF-8 bytes。
截断时还同步收窄 selection，避免光标落在新字符串长度之外。

Harmony 因而把 UI draft 上限设为 200。为避免 Java 路径可能产生的损坏 Unicode，Harmony 在恰好切进一对
surrogate 时退回一个 code unit；仍保持“不超过 200 UTF-16 units”的原版约束，但不会把孤立 high surrogate
交给 FlatBuffer UTF-8 writer。

## 2. 提交时仅空字符串回退，纯空格不 trim

`dp.java:227-242` 的 case 14 直接读取标题状态：

```java
String strB1 = (String) rd9Var3.L0.getValue();
if (strB1 != null) {
  if (strB1.length() == 0) {
    strB1 = rd9Var3.L.getString(R.string.feature_note__default_title);
  } else if (strB1.length() > 200) {
    strB1 = lvd.b1(200, strB1);
  }
  rd9Var3.l(m18.l0(xj2.d(dhh.a(strB1), null, null, null, null, null, null, null, 510)), null);
}
```

该路径没有 `trim()`。所以：

- `""` 提交为资源 `feature_note__default_title`；
- `"   "` 是合法标题，必须原样保存；
- 大于 200 的非空值再次防御性截断；
- `resources/res/values/strings.xml:459` 的资源值为 `New Note`。

Harmony 的 `commitOriginalNoteTitleDraft()` 据此只对 exact empty fallback，不把纯空格改成默认标题。

## 3. wire 是 `l2d.field0 → z2d.field0 → UTF-8`

`dhh.java:17-32` 把字符串写入单字段 `z2d SetString`；`z2d.java:24-29` 从 field 0（vtable offset 4）读取
字符串。`xj2.java:168-189` 的 `K()` 再把第一个 `z2d` 参数写入八字段 `l2d` 的 field 0：

```java
Integer title = z2dVar != null ? dhh.c(z2dVar, builder) : null;
builder.C(8);
if (title != null) builder.h(0, title.intValue());
if (pageBackground != null) builder.h(1, pageBackground.intValue());
```

`dp` 以 mask 510 调用 `xj2.d(...)`，只提供第一个 title 参数，其余字段全部缺省。因此正常标题提交是
**title-only** `SET_METADATA`：`l2d.field0` 存在，而 `l2d.field1 pageBackground` 缺省。缺省背景字段的语义是
“不修改背景”，绝不能被 Harmony reducer 当作 explicit-null 背景重置。

## 4. wire validator 允许 1..256 code units

`l2d.java:12-24` 的 `a()` 只在 title wrapper 的字符串非 null 时校验：空字符串报
`Title cannot be empty`，长度大于 256 报 `Title cannot exceed maximum length`。这与 UI 的 200 上限是两层
不同契约：本地编辑通常最多 200，但同步／导入 reducer 必须接受合法的 201..256 title operation。

Harmony 因而保留：

- UI draft 上限 200 UTF-16 units；
- wire 接受 1..256 UTF-16 units；
- UTF-8 编码预算最多 1024 bytes，并要求 encode/decode round-trip，拒绝损坏 Unicode。

## 5. title 与 background 是独立 LWW register

`v69.java:1161-1169` 在 payload type 1 分支分别处理两个字段：

```java
rz1.O(... "titleRegister" ..., operation, setMetadata.q());
m2d pageBackground = setMetadata.p();
if (pageBackground != null) {
  pageBackgroundRegister.c(operation, pageBackground.j());
}
```

title 总是交给独立 `titleRegister` 合并；背景只在其 wrapper 存在时处理。因此 title-only operation 不得读取、
比较或重写 background winner。Harmony reducer 也必须按字段存在性分别读取 winner、做 `(timestamp, site)`
比较并物化；相同 identity 不同完整值属于冲突，stale 值为 no-op。

## 6. 原版 Undo 读取旧标题并再次构造 `SET_METADATA`

JADX 无法结构化还原 `vnf.c()`，对 APK 本体执行：

```text
apkanalyzer dex code --class vnf com.gingerlabs.notability.apk
```

在 `SET_METADATA` 逆操作分支（标签约 `:cond_fa5`）可见：

```text
invoke-virtual {v5}, Ll2d;->q()Lz2d;
if-eqz v1, :cond_fc5
iget-object v1, v13, Lmnb;->I:Ljava/lang/Object;
check-cast v1, Lx09;
check-cast v1, La79;
invoke-virtual {v1}, La79;->f()Ljava/lang/String;
invoke-static {v1}, Ldhh;->a(Ljava/lang/String;)Lz2d;
...
invoke-static/range {v19 .. v27}, Lu5j;->H(...)Ll2d;
```

即：原 operation 含 title setter 时，逆操作从修改前的 `a79` 快照读取旧标题 `f()`，重新包成 `z2d`，再由
`u5j.H()` 构造另一条 `l2d SET_METADATA`。Undo 不是只改本地标题列，也不是写 Harmony 私有 UPDATE_TITLE
代替原版 operation；Redo 同理必须生成更新 identity 的新 title operation。

## 7. 新笔记 bootstrap 可能合并 title 与 background

`zm7.java:78` 的 note builder 路径把 title 与 `qgh.b(nz9)` 同时传给 `xj2.d(...)`，证明原版创建包允许首条
combined title/background `SET_METADATA`。本阶段只闭环已经存在笔记的本地标题编辑；Harmony `createNote()`
是否应改为 combined bootstrap，还需要继续追完整创建调用链、初始 operation 顺序和失败补偿，不能仅凭这一行
草率改写。该边界留给紧接的 bootstrap 阶段，而不是伪装成本阶段已完成。

## 文件 SHA-256

- `de4.java`：`F07EA829D5D748BE4DB995E5DC89D373E21057D8AF3DE52CEA08CC8BAEC21C9E`
- `dp.java`：`040DE7CC0BD5815C519589B2368A92BF4BF97687D1C345DB26AF92F8F72D03B7`
- `xj2.java`：`1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C`
- `l2d.java`：`59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8`
- `z2d.java`：`B65ADB097BD4621A054BACDFA94706DDB015AA8473F24149E0F7E6390553CA3E`
- `dhh.java`：`393843AF7454BDEF6DD8A4B06679CDD6548E3296183944A89F9521E8A680B900`
- `v69.java`：`69A28ACDF6B65139405E3F22B2EF42AC3DC8FF4E3D8054438EC54B745FE315EF`
- `vnf.java`：`076F6A267E50BA5565FDA4D6EDEFB8BDE9B05807A328C34D6B6C339E5BDCC157`
- `zm7.java`：`51C49E48B924345D2120A5BEF38A679D3F042349AA6EB8CF9E098DFA541C14A3`
- `strings.xml`：`31031CF5562FA308713A851E50FDAC9BE75DF325CF205C58F71DB42EE471DCC3`

## 尚需设备验证

本阶段不启动设备、模拟器、虚拟机或 Hypium。真机需验证中文/emoji 边界、纯空格标题、快速连续提交、
onSubmit + onBlur、返回手势、失败后重试、连续 Undo/Redo、杀进程重开、搜索结果与最近修改排序，以及真实上传
ACK／重新下载后的 title LWW 表现。

## Phase 246 Follow-up

第 7 节当时只凭 `zm7` 判断“可能合并”。Phase 246 已继续复核 `id7.d()/h()`、`haj/ln2`、`pq1/oq1` 与
APK DEX，确认普通空白新笔记固定先写 combined title/background `SET_METADATA`，随后写一个
`pageCount=2` 的 CREATE_PAGE。完整线性证据移至
`docs/migration/evidence/original-blank-note-bootstrap-jadx-dex-2026-08-16.md`；本文件其余关于既有笔记
title-only 编辑的证据不变。

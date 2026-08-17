# 原版 SET_METADATA 六项独立寄存器证据（2026-08-18）

## 1. 基准与文件哈希

原版只读基准：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 本阶段用途 |
|---|---|---|
| `l2d.java` | `59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8` | SET_METADATA 八字段读取与校验 |
| `xj2.java` | `1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C` | 八字段 FlatBuffer 编码顺序和 scalar presence |
| `rz1.java` | `99B3433644F2BDCFC139EB96FDEEB120F7A87A5BDA693D066DE905116B9E2A86` | wrapper-null 与普通 nullable 字段的写寄存器区别 |
| `fqb.java` | `9081D6F7BA36C4F97B64051D13468AB7C11C797A5DC497E2D46193268C5BE634` | Register.Builder 的严格 greater 更新 |
| `so5.java` | `BA88BD05E24494B42D1DF413DB22BBEAE9B96C609AD8518717666BA5C9737E96` | unsigned timestamp/site 比较 |
| `v69.java` | `69A28ACDF6B65139405E3F22B2EF42AC3DC8FF4E3D8054438EC54B745FE315EF` | 八字段分别落入八个寄存器 |
| `a79.java` | `FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13` | NoteImpl 的持久寄存器状态 |
| `u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | 笔记快照重新序列化 SET_METADATA |
| `tv6.java` | `AA16B39CFA8E2314C044BCCFB9B2DE99C817CC2523189E09D23D9CC20C5E6AD9` | PAGED/PAGELESS byte 值 |
| `dz0.java` | `69D976A9C990B47895DDAE50C02905164DEACD8BF982304CD9998E50EA12E3C3` | 三种 block wrap byte 值 |
| `x82.java` | `2F84DD82F20472A13B882D8123D066CA7D8B2EFF181C87ECE3B43219F927C7CC` | layoutMode 页面布局 consumer |
| `z5c.java` | `3F0280BF8F355E595798789B1A1D1CCB85EFF9D349323ADFF0B1B66840289DEC` | pageless 页面偏移 consumer |
| `yo7.java` | `55AA97A7466A310527526B6C5D124C5AA80314ECF7F9E273AD3527620B2C313C` | align/layout 状态读取 |
| `jc5.java` | `A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405` | handwriting language consumer |

## 2. wire layout：八字段不是一个整体设置对象

`l2d.java:79-167` 的 accessor 对应如下：

| FlatBuffer field | `l2d` accessor | 语义 | presence |
|---:|---|---|---|
| 0 | `q()` / `c(4)` | title | `z2d` wrapper，可区分缺席与 wrapper 内值 |
| 1 | `p()` / `c(6)` | pageBackground | `m2d` wrapper，可表达显式 null |
| 2 | `n()` / `c(8)` | handwritingLanguage | `z2d` wrapper，可表达显式 null |
| 3 | `j()` / `c(10)` | alignTextToLines | nullable boolean scalar |
| 4 | `l()` / `c(12)` | defaultFontFamily | nullable string |
| 5 | `m()` / `c(14)` | defaultFontSize | nullable Float32 |
| 6 | `o()` / `c(16)` | layoutMode | nullable byte enum |
| 7 | `k()` / `c(18)` | blockWrapSupport | nullable byte enum |

`xj2.java:168-207` 先 `C(8)` 建立八字段表，再按 field 0～7 写入。boolean、layout 和 wrap 写入前暂时把
FlatBuffer builder 的 force-default 标志设为 true，因此“字段缺席”和“显式 false/0”不能用读取后的数值相等来
混淆；Harmony 必须先检查 vtable presence。`xj2.java:700-735` 的构造入口也保留这八个独立 nullable 参数。

## 3. handwriting 的显式 null 与其他 nullable 字段不同

`rz1.java:246-251` 的 `O(...)` 只在 wrapper 自身缺席时跳过；wrapper 存在时无条件把 `z2d.j()` 写入寄存器，
所以 field 2 可以把 handwriting language 显式清为 null。

`rz1.java:269-274` 的 `R(...)` 则先检查普通对象是否为 null；align、font family、font size、layout 和 wrap
只有字段实际存在时才写寄存器。Harmony 因此保留：

- `hasHandwritingLanguage=false`：没有 patch；
- `hasHandwritingLanguage=true, handwritingLanguage=null`：明确清空；
- 其他五个 scalar/string 字段：以 vtable presence 表示是否 patch。

## 4. 原版校验与 Harmony fail-safe

### 4.1 原版直接证据

`l2d.java:12-52` 依次校验：

- title 非空且最多 256 个 Java UTF-16 code unit；
- page background 自身合法；
- note-level template PDF 的 `pagesConsumed` 必须严格等于 1；
- default font size 不得 `<= 0.0f`；
- default font family 最多 30 个 Java UTF-16 code unit；
- handwriting language 只取首个 `_` 前的精确前缀，并要求属于 `Locale.getISOLanguages()`。

Java 17 的该列表共 188 项，包含现代/旧别名 `he/iw`、`id/in`、`yi/ji`；Harmony policy 固化同一 188 项，
大小写和连字符都不归一化。因此 `en_US` 合法，`EN_US`、`en-US` 和 `zz_US` 非法。

`tv6.java` 固定 `PAGED=0`、`PAGELESS=1`；`dz0.java` 固定 `WRAP_ENABLED=0`、
`WRAP_DISABLED=1`、`LEGACY_WRAP_ENABLED=2`。

### 4.2 明确的平台加固

Java 的 `float <= 0` 对 `NaN` 和 `+Infinity` 都返回 false，原版 validator 会放行这两种非有限值。Harmony 若把它们
写入 SQL 或交给字体 consumer，会制造不可排序/不可渲染状态，因此本阶段收紧为“有限且大于 0”。这是数据完整性
加固，不冒充原版分支。

handwriting string 的原版没有显式总长度上限；Harmony FlatBuffer decoder 使用 1024-byte 分配预算，family 使用
120-byte 预算后再按 30 UTF-16 单元校验。前者是恶意包内存门，后者足以覆盖 30 UTF-16 单元的 UTF-8 表达；两者都不
改变正常 locale/font name。

## 5. 每个字段拥有独立严格 LWW 寄存器

`v69.java:1161-1213` 对同一个 `l2d` 依次取得：

- `titleRegister`；
- `pageBackgroundRegister`；
- `handwritingLanguageRegister`；
- `alignTextToLinesRegister`；
- `defaultFontFamilyRegister`；
- `defaultFontSizeRegister`；
- `layoutModeRegister`；
- `blockWrapSupportRegister`。

它们不是共享一个 winner。一次 SET_METADATA 可以让某些字段获胜、另一些字段因已有更新 winner 而 no-op。

`fqb.java:24-32` 只有 `so5.a(new, old) > 0` 才替换；`so5.java:10-13` 先 unsigned 比较 32-bit timestamp，
相同 timestamp 再比较 unsigned 16-bit site。因此：

- newer field 更新；
- stale field 完整 no-op；
- 相同 identity 原版保持旧值。

Harmony 延续既有 title/background 保护：相同 identity、相同完整值视为幂等；相同 identity、不同值视为损坏/冲突，
整条 inbox operation deferred。该检查比原版“静默忽略”更严格，用于阻止同一 operation identity 对应两份不同 payload。

## 6. 六项是 NoteImpl 持久状态并进入原版快照

`a79.java:59,71-109,132-139,150-152` 把 default family、default size、align、layout、wrap、handwriting 都保存为
独立 `yc6` register；它们参与 copy/NoteImpl 生命周期，而不是只在操作解析期间临时存在。

`u5j.java:366-380` 从上述寄存器取出六项，并调用 `xj2.d(...)` 重新生成 SET_METADATA，证明这些值进入原版笔记
快照/重建链。Harmony 本阶段提供经校验的 SQL readback 投影，但尚未新增六项本地编辑器出站 writer；不能把
“可持久读取”表述为 Harmony UI 已具备原版同等设置入口。

## 7. 已证明的 consumer 与不能猜的连接

- `x82.java:1198-1210` 只在非 PAGELESS 下计算分页纸张间距；
- `z5c.java:2379-2392` 在 PAGELESS 下把顶部纸张偏移归零；
- `yo7.java:360-374` 读取 align 和 layout 状态；
- `jc5.java:149-157` 把 handwriting register 交给 locale/recognition 配置选择。

静态搜索没有证明 `defaultFontSize` 会直接替代 CREATE_BLOCK 的初始字号，也没有证明所有 wrap/default-font UI/renderer
路径。故本阶段不修改 Harmony 现有固定 `17`，不发明未证明的默认字体消费规则。

## 8. Harmony 实现映射与事务边界

数据库 v65 新增六张 `note_id` 主键 winner 表，每张只保存一个字段、自己的 `(winner_timestamp,winner_site_id)`，并以
`ON DELETE CASCADE` 跟随 `note_meta`。应用层先完成 wire decode、全部值校验、全部 winner 读取和全部 identity
冲突判断，再开始任何 winner/materialized write。

复核时发现旧 title/background 路径会在 LWW 判断前调用 `mergeOriginalAssetReference()`：stale PDF 背景也可能附加
资产，或后续六项 identity conflict 返回 deferred 时留下资产副作用。Phase 270 将它移到全部冲突判断之后，并只在
background winner 确实获胜时执行。由于 inbox 会提交 deferred 状态，这一顺序是原子性必需条件。

一次混合操作只在至少一个字段实际变化时推进一次 `structure_revision`。blank-note bootstrap 的 fresh gate 也纳入六张
新表，避免残留 metadata winner 被误判为全新空白笔记。

## 9. Replay/fixture 口径

`docs/migration/replays/d02-original-set-metadata-registers.mjs` 同时锁定：

- 上述原版源码门、188 项语言表与 enum 值；
- v65 六表建表、约束和六表 cascade；
- 八字段独立 LWW、stale no-op、site tie-break、幂等与 same-identity conflict；
- 混合 title/background/六项在冲突前零写入，stale PDF 不附加资产；
- handwriting 显式 null、非法 language/family/size/enum/PDF page count；
- production 写入顺序、单 revision、readback、bootstrap fresh gate；
- ArkTS FlatBuffer fixture、policy fixture、数据库 fixture 与 suite 注册。

ArkTS `note@ohosTest` 只证明这些 fixture 完成编译/打包，不代表执行了设备 Hypium assertion。

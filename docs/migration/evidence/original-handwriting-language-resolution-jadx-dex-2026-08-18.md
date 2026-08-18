# 原版手写识别语言解析与 Provider 笔迹/参数证据（2026-08-18）

## 1. 范围与只读基准

本阶段只研究原版 1.0.3 在手写转文字前如何选择识别语言、如何把语言传给 MyScript，以及 Harmony 在尚无
生产 OCR provider 时应如何保留该边界。Desktop `Notability` 目录仅作原版 APK/JADX/临时逆向证据源；所有
Harmony 源码、测试、Replay、ADR 和 Report 只写入 `C:\HarmonyProject\NotaHarmony`。

原版主源码：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 关键位置 | 证明 |
|---|---|---:|---|
| `dc5.java` | `9AA6A03B888842A1BD217F50DA9A7CB55B5DAE0D1124EADB895E949393D33ECA` | 23-81 | 23 组 `localeCode/tag`、英文默认项、繁体中文地区集合 |
| `sh8.java` | `D6BFD57D268CA9EF810744134407E09BD96F2DA85FE689D333391E737ABA499D` | 66-79, 102-148 | exact lookup、note/global/system/default 优先级、中文与 `tl/in` 特殊映射 |
| `jc5.java` | `A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405` | 149-157 | 从当前 NoteImpl register、全局偏好和系统 Locale 组装语言选择输入 |
| `hc5.java` | `9F524AADE41D95ECF36DBE24B69E4A19587932B3DF8FA134A8EE4E37A3C56E5C` | 85-93 | 空选区不调用识别器；非空选区把 `dc5` 交给 text recognition |
| `pm8.java` | `96DCE90733FCD3137EC49B31552AC7D85153425D735EDCD308B9536E58778064` | 89-198, 243-299, 321-344, 349-451 | 每条 Ink 独立 pointer 序列并保留 force；MyScript `lang` 与 `recognizer.lang` 使用 `dc5.I`，recognizer type 为 `Text`；调用为 coroutine |
| `l2d.java` | `59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8` | 41-51 | metadata 只校验 `_` 前 ISO language prefix，不等于该值一定是 `dc5` 支持项 |

原版 APK：`Notability_1.0.3\com.gingerlabs.notability.apk`
APK SHA-256: `3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`

## 2. 原版解析顺序

`jc5.e()` 依次取得：

1. 当前笔记 `a79.A` 的 handwritingLanguage register；
2. `kc5` 暴露的全局语言偏好；
3. `Locale.getDefault()`。

随后调用 `sh8.D(note, global, locale)`。`sh8.B()` 对输入执行大小写敏感的 exact match：只接受 `dc5.I`
（如 `zh_TW`）或 `dc5.J`（如 `zh-Hant`）。因此 `en_GB` 虽能通过 `l2d` 的 ISO prefix 校验，却不是原版
recognizer 列表项；它不会被猜成 `en_US`，而是继续尝试全局偏好和系统 Locale。

`sh8.D()` 的优先级为：

```text
recognized note register
→ recognized global preference
→ mapped system Locale
→ dc5.L = English (en_US/en)
```

中文系统 Locale 的分支为：

- script=`Hant` → `zh_TW/zh-Hant`；
- script=`Hans` → `zh_CN/zh-Hans`，即使地区是 HK/TW/MO；
- script 未明确且地区为 `TW/HK/MO` → `zh_TW/zh-Hant`；
- 其余中文 → `zh_CN/zh-Hans`。

## 3. APK DEX 对损坏 JADX switch 的纠正

`sh8.java:126-140` 的 Java 反编译把一个 hash switch 压坏成了看似恒定的 `nb` 分支。使用 Android SDK：

```powershell
apkanalyzer dex code --class sh8 `
  --method 'D(Ljava/lang/String;Ljava/lang/String;Ljava/util/Locale;)Ldc5;' `
  com.gingerlabs.notability.apk
```

APK DEX 明确给出四个 legacy/system 分支：

```smali
const-string v0, "no"
invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
...
const-string v0, "nn"
invoke-virtual {p1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
...
const-string p1, "nb"

const-string v0, "tl"
...
const-string p1, "fil"

const-string v0, "in"
...
const-string p1, "id"
```

因此系统 Locale 的 `no` 与 `nn` 都映射到原版唯一 Norwegian recognizer `no_NO/nb`；`tl → fil`，
`in → id`。这些是 APK bytecode 事实，不采用损坏 Java switch 的字面结果。

本轮为 DEX 定位机械提取了只读临时文件：
`C:\Users\Cisco He\Desktop\Notability\.codex-tmp-phase274-dex\classes.dex`，大小 `7,469,228` bytes，
SHA-256 `6425BCDD11AA94AA3E6ECCFBCCDDE70B08F451C96CEC34CCD947F26BC26F8819`。该文件不进入 Harmony Git，
也不是鸿蒙源码工作树。

## 4. Provider 真正消费的笔迹与字符串

`hc5` 对非空笔迹集合执行 `jc5.e()`，再把得到的 `dc5` 交给 suspend `pm8.c()`。`pm8.a()` 不会把选区压成
一条扁平折线：它按排序后的每个 `s06` 分别发送 `pointerDown → pointerMove* → pointerUp`，并把每个 `po4.f`
作为 force 传入；坏的单条 center path 会 `pointerCancel()`，不会改变其他笔迹的边界。`pm8.b()` 为 Text
recognizer 配置：

```java
configuration.setString("lang", dc5Var.I);
configuration.setString("recognizer.lang", dc5Var.I);
```

所以 provider 的输入必须是完整 `localeCode`（例如 `zh_TW`），不能误传仅用于查找/展示的 tag
`zh-Hant`。

## 5. Harmony 映射与明确未闭环项

Harmony 新增纯逻辑 policy，固定 23 组 `dc5` 值、四级优先级、中文 script/region、`no/nn/tl/in` 映射和
英文 fallback；另新增异步、language-aware OCR provider 边界，输入保留多条笔迹的顺序、分段与 force，只有
独立 provider 可用且选区非空时才调用，并把 `localeCode` 传入。

当前工程只有 ShapeDetector，自身 `recognizeText()` 返回 null，也没有 MyScript/Harmony OCR provider、全局
handwriting preference adapter、`StrokeElementData → page-space recognition strokes` 适配器或选区“转文字”
入口。因此本阶段明确保持 fail-closed：不把 ShapeDetector 的
`isAvailable()` 当成 OCR 可用，不伪造识别结果，也不宣称手写识别功能已经上线。设备语言 API 适配、真实 provider、
设置 UI、选区入口、结果写回/Undo 和性能继续开放。

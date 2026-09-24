# Phase 689 — 原版字体样式预设（hr4 / ote）Evidence

## 范围

把原版字体样式面板的 6 项样式预设（Large Title → Caption）移植到
Harmony 文本块编辑覆盖层：`zyd{bold, italic:false, fontSize}` 三字段
原子写 + 折叠光标预期属性。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/hr4.java` —— 预设枚举

```java
gr4 "LargeTitle", 0, true,  36.0f
dr4 "Heading1",   1, true,  30.0f
er4 "Heading2",   2, true,  24.0f
fr4 "Heading3",   3, true,  18.0f
br4 "Body",       4, false, 14.0f   // K = 缺省
cr4 "Caption",    5, false, 12.0f
```

`hr4.I` = 是否加粗；`hr4.J` = 字号（pt）。

### 2. `sources/defpackage/cve.java` —— `ote` 分支（L255-260）

```java
if (nueVar instanceof ote) {
    hr4 hr4Var = ((ote) nueVar).a;
    n(new zyd(Boolean.valueOf(hr4Var.I),   // bold = 预设加粗
              Boolean.FALSE,               // italic 显式清除
              null, null, null,
              Float.valueOf(hr4Var.J),     // fontSize = 预设字号
              null, null, null, null, null,
              2012));                      // mask：args 1/2/6 显式下发
    i(qse.L);                              // 关闭样式面板
    return;
}
```

**三字段原子写**：bold 随预设、italic 恒显式 FALSE（清除斜体）、
fontSize 写预设值 —— 预设即 {bold,size} 组合，italic 必然被清。

### 3. `cve.java` —— `l(float f)`（L404-407）

```java
n(new zyd(null, null, null, null, null,
    Float.valueOf(rh8.u(f, 4.0f, 72.0f)),   // fontSize clamp [4,72]
    null, null, null, null, null, 2015));   // mask：arg6 显式下发
```

字号字段独立写路径（`pte` → `l(pte.a)` 文本尺寸事件经此）。

### 4. `sources/defpackage/i31.java`

字体样式面板项点击 → `ix4Var.invoke(new ote(hr4Var))`（同文件另有
`new nte(zq8Var)` 字体族事件——字体族属后续 Phase）。

### 5. 字符串

`ui_text__font_style_large_title`="Large Title"、`_heading_1/2/3`、
`_body`="Body"、`_caption`="Caption"。

## Harmony 现状（Phase 689 之前）

- `RichTextCharacterStyle.fontSize?: number` 字段存在。
- `br2.h` 对应物：无字号 authoring 入口（仅元素级 `element.fontSize`）。
- Phase 684/688 字符 run 管线 + pending 落地机制齐备。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `ote`→`zyd{I,FALSE,J}` mask2012 | `applyTextStylePreset(bold,fontSize)` 单趟区间三切分：`mid.bold=bold; mid.italic=false; mid.fontSize=fontSize` + gap-fill `{bold,italic:false,fontSize}` —— 原子写三字段 |
| `hr4` 6 预设表 | `buildTextStyleMenu()` 6 项 bindMenu（36/30/24/18 bold + 14/12 非 bold） |
| `i31` 面板（字体样式区） | `Style` 按钮 + 菜单，置格式行行首（bold 之前） |
| 折叠光标预期 | pendingCharStyles 合并 `{bold,italic:false,fontSize}`；落地经 fields 循环（bold/italic 经 `applyCharStyle` 显式写）+ `applyFontSize` |
| `l(f)` 独立字号写 | `applyFontSize(size\|null)`（null 清除；预设菜单不产生 null，为后续独立字号控件预留） |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-text-style-presets.mjs`：16 项静态钉全绿。

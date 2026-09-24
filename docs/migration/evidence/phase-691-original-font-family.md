# Phase 691 — 原版字体族（nte → zyd.e familyName）Evidence

## 范围

把原版 `i31` 字体面板的字体族选择（`nte`/`zq8`/`qr4`）移植到 Harmony
文本块编辑覆盖层：`familyName` 字符样式 run 的写入、选区应用、
折叠光标预期属性和 Default 缺省恢复。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— `nte` 分支（L261-266）

```java
if (nueVar instanceof nte) {
    n(new zyd(null, null, null, null,
        ((nte) nueVar).a.a,          // arg5 = zq8.a modelName → familyName
        null, null, null, null, null, null,
        2031));                       // mask：arg5 显式下发
    i(qse.N);                         // 关闭字体面板
    return;
}
```

`nte.toString = "OnFontFamilyValueChanged(font=...)"`。

### 2. `sources/defpackage/zq8.java` —— NbFont

```java
zq8{ a: modelName, b: displayName, c: sq4 fontFamily }
toString → "NbFont(modelName=..., displayName=..., fontFamily=...)"
```

### 3. `sources/defpackage/qr4.java` —— 字体注册表

```java
kr4VarB  = Roboto（variablefont + bold + italic）
kr4VarB2 = Inter（variablefont_opszwght + italic）
kr4VarB3 = EBGaramond（variablefont + italic）
c/d = [zq8("Inter","Inter"), zq8("Roboto","Roboto"),
       zq8("EBGaramond","EB Garamond")]
b = zq8Var = Inter                        // 缺省字体
g = {NotoSerif, NotoSansMono, CutiveMono, DancingScript,
     ComingSoon, CarroisGothicSC}          // 服务端下载字体表（非随包）
qr4.b(String modelName) → 反查，缺省回退 Inter
```

### 4. `sources/defpackage/i31.java`

字体族项点击 → `ix4Var.invoke(new nte(zq8Var))`（与 `ote(hr4)` 样式预设
同一面板的不同区块）。

### 5. `sources/defpackage/zyd.java`

`public final String e` —— `zyd` 第 5 字段即 familyName 负载槽。

## Harmony 现状（Phase 691 之前）

- `RichTextCharacterStyle.familyName?: string` 字段存在；
  `Canvas2DTextRenderer` 字体令牌已用
  `style.familyName === undefined ? 'sans-serif' : '"'+familyName+'"'`。
- 缺口：**无 authoring 入口**。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `i31` 字体族区 → `nte(zq8)` | `Font` 按钮 + `bindMenu`（Inter/Roboto/EB Garamond/Default） |
| `zyd.e = zq8.a` modelName | `applyFontFamily(name\|null)` 写 `familyName` run；落库为 modelName（"EBGaramond"），菜单展示 displayName（"EB Garamond"） |
| `qr4.b` = Inter 缺省 | `Default` 项 → `applyFontFamily(null)` 置 `familyName=undefined`（渲染回退 sans-serif ≈ 元素缺省） |
| 折叠光标预期 | `pendingCharStyles.familyName` + `pendingClearFamily` |
| `qr4.g` 下载字体（服务端） | 不在移植范围——服务端资源，登记缺口 |

## 受限等价说明（非 ADR 级）

- 原版随包带 Inter/Roboto/EBGaramond 字体资源（res/font）。Harmony 侧
  **未内嵌字体文件**：`familyName` 字段忠实持久化（.note 往返无损），
  但渲染时 HarmonyOS 以字体名匹配系统字体——无同名字体时按平台字体
  替换规则回退。字形差异属运行环境限制（与 ADR-0648 渲染端缺口同族），
  字体资源内嵌为后续工程项，记入此节而非新 ADR。
- 菜单为文本列表，非原版面板带字体预览样式。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-font-family.mjs`：16 项静态钉全绿。

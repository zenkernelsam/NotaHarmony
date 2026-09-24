# Phase 688 — 原版文本高亮（Highlight / Remove Highlight）Evidence

## 范围

把原版富文本高亮动作（`rte` → `zyd.d` 的 `eh5` 负载，以及 `zte` 清除路径）
移植到 Harmony 文本块编辑覆盖层：`highlightColor` 字符样式 run 的写入、
选区应用、折叠光标预期属性和清除操作。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— `rte` 分支（L134-156）

```java
boolean zEquals2 = nueVar.equals(rte.a);          // 高亮按钮点击
if (zEquals2) {
    uub uubVarB = j().b();
    boolean zL = (uubVarB == null || (jtcVar = uubVarB.d) == null
        || (fkeVar = jtcVar.a) == null) ? true : fkeVar.l();  // 色板面板是否关闭
    eh5 eh5Var = ((br2) ufbVar.I.getValue()).g;   // 当前高亮态 {color,isActive}
    ufb ufbVar2 = this.Z;                          // 色板选中色状态
    if (zL) {
        // 面板关 → 直接把色板当前色写入 zyd.d
        n(new zyd(null, null, null,
            new eh5(((iu1) ufbVar2.I.getValue()).a, true),
            null, null, null, null, null, null, null, 2039));
        return;
    }
    if (!eh5Var.b || !tmf.a(eh5Var.a, ((iu1) ufbVar2.I.getValue()).a)) {
        // 未激活或色不同 → 用色板色重设（fm7.e.f(color) 应用）
        j().e.f(((iu1) ufbVar2.I.getValue()).a);
        return;
    }
    // 同色且已激活 → 打开取色面板（qse.S），不重复写样式
    qse qseVar4 = qse.S;
    asdVar3.k(null, qseVar4);
    return;
}
```

### 2. `cve.java` —— `zte` 清除分支（L385-393）

```java
if (nueVar.equals(zte.a)) {                        // OnRemoveHighlight
    fm7Var2.c.U("removeHighlightFromSelection", new yl7(fm7Var2, 2));
    qs3Var2.invoke();                              // （若有回调）
    i(qse.S);                                      // 关闭取色面板
    return;
}
```

`lhb.java` case 27 → `ix4Var.invoke(zte.a)`（选择菜单 Remove Highlight 项）。
`aj4.java` op type 4 `toString = "RemoveHighlight: range: ..."` ——
对选中区间执行高亮 span 清除（`h50Var.d(m18.l0(...))` 区间样式 op）。

### 3. `sources/defpackage/eh5.java`

```java
public final class eh5 {
    public final long a;     // iu1 颜色（long ARGB）
    public final boolean b;  // isActive
    toString → "HighlightData(color=..., isActive=...)"
}
```

`zyd.java`：`public final eh5 d` —— `zyd` 字符样式负载第 4 字段即高亮
（与 P684 解码的 `a`=bold / `b`=italic / `c`=underline / `k`=strikethrough /
`i`=subscript / `j`=superscript 同一分派表）。

### 4. `fm7.java` —— 选区应用

```java
this.c.U("applyStyleToSelection",
    new nx6(i, this, new zyd(null, null, null, new eh5(j, true),
        null, null, null, null, null, null, null, 2039)));
```

### 5. 字符串

- `feature_note__selection_menu_highlight` = "Highlight"
- `feature_note__selection_menu_remove_highlight` = "Remove Highlight"
- `ui_tools__remove_highlight` = "Remove highlight"

## Harmony 现状（Phase 688 之前）

- `RichTextCharacterStyle.highlightColor?: number` 字段存在；
  `Canvas2DTextRenderer` 已在 `style.highlightColor !== undefined` 时
  于文字背后 `fillRect` 绘制高亮矩形。
- Phase 684 已建 `draftCharRuns`/`pendingCharStyles`/`applyCharStyle`/
  `normalizeCharRuns` 字符样式管线。
- 缺口：**无 authoring 入口**（高亮字段有渲染无写入）。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `rte` 点按写 `eh5{色板色,true}` | `toggleHighlightColor(color)` → `applyHighlightColor(color,s,e)` 写 `highlightColor` run |
| `br2.g`（HighlightData 态） | `@State caretCharHighlight` + `rangeHasHighlight`（选区全覆盖判定）/ pending 检查 |
| `zte`→`removeHighlightFromSelection` | `clearHighlight()` → `applyHighlightColor(null)` 置 `highlightColor=undefined`，normalize 以 `JSON.stringify(style)!=='{}'` 剔除空样式 run |
| 折叠光标预期高亮 | `pendingCharStyles.highlightColor` + `pendingClearHighlight`（兄弟 run 高亮中输入时显式清除） |
| 色板/`qse.S` 取色面板 | 受限等价：`bindMenu` 五色预设（40% α 荧光笔色）+ Remove Highlight 项；同色再点不再打开面板（差异见报告/本节） |
| 选择菜单 Highlight / Remove Highlight | 工具条 Highlight 按钮 + 菜单（Harmony 选择菜单为系统级，不注入自定义项——既有注册差异，见 ADR-0650 族） |

## 受限等价说明（非 ADR 级）

原版 `rte` 的交互是"色板驱动"：按钮显示当前色板色，点按应用之；同色已激活
时再点才弹取色面板。Harmony 侧无全局色板状态（`this.Z`/`uub`），用
`bindMenu` 五色预设菜单承载同语义：点菜单项=应用该色（等价 `eh5{color,true}`），
"Remove Highlight"项=`eh5` 清除路径（`zte`）。差异仅为取色面板的自由取色
能力——预设五色覆盖原版默认高亮色谱（黄/绿/青/粉/橙），属受限等价而非
语义偏差，故不立新 ADR（沿用 ADR-0650 字符样式分派框架）。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-highlight-color.mjs`：20 项静态钉全绿。

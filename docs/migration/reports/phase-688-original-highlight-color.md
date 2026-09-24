# Phase 688 — 原版文本高亮（Highlight / Remove Highlight）移植

## 范围

`rte`/`zte` 高亮动作（`zyd.d` 的 `eh5` HighlightData 负载）补进
`TextBlockOverlay`：字符级 `highlightColor` run 的写入、选区应用、
折叠光标预期属性和清除操作。渲染端（`Canvas2DTextRenderer` 文字背后
`fillRect`）与模型字段此前已就位，本期补齐 authoring 缺口。

## 原版行为（证据见 phase-688 evidence）

- `cve.java` `rte` 分支：点按把色板当前色写入选区
  `zyd(..., new eh5(iu1.a, true), ...)`；同色且已激活时再点弹取色面板
  （`asd.k(null, qse.S)`），不产生冗余样式 op。
- `cve.java` `zte` 分支（OnRemoveHighlight，选择菜单 case 27 触发）：
  `removeHighlightFromSelection` → `aj4` op type 4
  "RemoveHighlight: range" 清除选区高亮 span，随后 `i(qse.S)` 收面板。
- `eh5` = `HighlightData(color: long, isActive: boolean)`；
  `zyd.d` 为其载体字段。
- 字符串：`feature_note__selection_menu_highlight`="Highlight"、
  `feature_note__selection_menu_remove_highlight`="Remove Highlight"。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `applyHighlightColor(color: number | null, s, e)`：与 `applyCharStyle`
    同构的区间三切分；`null` → `highlightColor=undefined`（`zte` 清除语义），
    非 null → 写入并对选区空白段 gap-fill `{highlightColor: color}`。
  - `toggleHighlightColor(color)`：选区写 run；折叠光标写
    `pendingCharStyles.highlightColor`（预期输入属性）。
  - `clearHighlight()`：选区 `applyHighlightColor(null)`；折叠光标置
    `pendingClearHighlight`——在高亮兄弟 run 中输入时显式清除而非继承。
  - `rangeHasHighlight`：选区被 `highlightColor` 非空 run 全覆盖判定，
    驱动 `@State caretCharHighlight` 按钮激活态。
  - `buildHighlightMenu()`：五色预设（黄/绿/青/粉/橙，40% α 荧光笔色）
    + Remove Highlight 项的 `bindMenu`；按钮置 strikethrough 之后、
    列表装饰之前（字符样式簇末位）。
  - `normalizeCharRuns` 空样式判定改 `JSON.stringify(style)!=='{}'`：
    清除后残留的 `{highlightColor:undefined}` 被规范剔除（`Object.keys`
    会误计该键）。
  - pending 落地：`pendingClearHighlight` → `applyHighlightColor(null)`；
    否则 `pendingCharStyles.highlightColor` → `applyHighlightColor(color)`。
- 新增字符串 ×7（en/zh）：`text_highlight`、五色名、`highlight_remove`。

## 与原版差异（受限等价，未立新 ADR）

- 原版按钮色板驱动（`this.Z`/`uub`）：同色再点弹 `qse.S` 取色面板。
  Harmony 无全局色板态，`bindMenu` 五色预设承载同语义；自由取色能力
  缺省，但默认色谱覆盖（黄/绿/青/粉/橙为荧光笔常用色）。差异记录于
  evidence 文档"受限等价"节，沿用 ADR-0650 字符样式分派框架。
- 选择菜单（系统级 ActionMode）项不注入——既有注册差异同 ADR-0650 族。

## 验证

- Replay：`d02-original-highlight-color.mjs` 20 项全绿；lease-bound
  enabled 计数 17→18。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 沿用 ADR-0648/0650 登记差异（CRDT 读侧解码有、写侧无本地 style-op
  编码器等）。
- 取色面板自由取色未实现（见上）。
- 高亮按钮为文本形态，非原版色板缩略图样式。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-highlight-color.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`

# Phase 683 证据 — 原版文本格式工具条列表装饰项（BULLET/NUMBER/CHECK_BOX）

## 原版证据（decompiled_1.0.3）

| 文件 | 证据 |
|------|------|
| `sources/defpackage/fy2.java` | 段落装饰枚举：NONE=0、BULLET=1、NUMBER=2、CHECK_BOX=3、BLOCK_QUOTE=4、CODE_BLOCK=5。 |
| `sources/defpackage/h32.java` | case24/25/26：`ui_text__bullet_list`/`ui_text__numbered_list`/`ui_text__checkbox_list` 图标+文案行（`go5.b` 菜单项，medium 图标）。 |
| `sources/defpackage/cve.java` | UserAction 分发：`yse`→`o(fy2.BULLET)`、`xte`→`o(fy2.NUMBER)`、`zse`→`o(fy2.CHECK_BOX)`；`o(fy2)` → `m(m5a(fy2Var))` 段落样式 op（单选互斥，同值再点为清除）。 |
| `resources/res/values/strings.xml` | `ui_text__bullet_list`="Bullet list"、`__numbered_list`="Numbered list"、`__checkbox_list`="Checkbox list"。 |

## 原版行为

- 文本格式工具条中列表三项与 Block quote/Code block 同处段落装饰位：
  单选互斥（一个段落同一时刻只能有一个 decorator），同项再点回 NONE。
- CHECK_BOX 的勾选态是段落样式之外的独立字段（`isChecked`），切换
  decorator 不清除既有勾选记录。
- 作用粒度 = 当前段落（段落样式 run）。

## Harmony 实现（本 Phase）

- `TextBlockOverlay.ets`：底部行在 Block quote 之前新增
  Bullet list/Numbered list/Checkbox list 三枚切换钮（h32 序位）；
  复用 Phase 681 的 `draftStyles`（段落序号键）→ `computeParagraphRuns`
  （字符区间 run）→ `onTextCommit` 管线。
- `toggleDecoratorStyle(1/2/3)`：互斥单选；`isChecked`/`indentLevel`/
  `alignment`/`lineSpacing`/`writingDirection` 跨切换保留（与原版
  独立字段语义一致）。
- 渲染侧既有：`Canvas2DTextRenderer` 已按 decorator 1/2/3 渲染
  圆点/自增编号/checkbox 标记列（含 `drawCheckboxMarker` + 命中区），
  本期仅补 authoring 面。
- 资源：`bullet_list`/`numbered_list`/`checkbox_list` base+zh。

## 等价与差异

- 与 P681 相同的两个已登记差异沿用 ADR-0648：CRDT 块样式-only 提交
  停留元素级（无本地段落样式 op 编码器）；rollout 旗标无条件放开。
- 列表三钮与 quote/code 同粒度（光标所在段落）——原版同粒度，无新差异。

# 证据：原版荧光笔 underlay z 带探针（u5j.g / u5j.j / g1f）

- 日期：2026-09-28；Phase 628
- 原版来源：`decompiled_1.0.3/sources/defpackage/u5j.java`、
  `g1f.java`、`dm2.java`、`u16.java`、`cfc.java`
- Harmony 实现：`note/src/main/ets/data/StrokePersistence.ets`

## 原版语义

`u5j.g`（u5j.java:557-663）是 CreateInk（`dm2`）op 的统一生产者，
`faj.a(...)` 收 `xgb`（zIndex）形参。`xgbVar == null`（调用方未指定
zIndex）且 `u16Var2 == u16.HIGHLIGHTER`（u16.java:20，HIGHLIGHTER=2）
时，生产者对文档做一次起点探针（u5j.java:581-655）：

1. `fqaVarA = hqa.a(fqaVar, bmbVar.c())` —— 把笔迹起点换算到文档坐标；
   页面不在 `map`（`bmbVar == null`）时探针直接放弃（`fqaVarA = null`）。
2. 顺序遍历 `qjaVar.I`（存活 Ink，仅 `xy0` 实例且 `!ba6.K(id, cl2)`
   未被标记）与 `uiaVar`（元素表，跳过 `ba6.K` 标记项与已登记为 Ink 的
   键），对每个 `ba6.k(...)` 边界做闭区间包含测试
   `k11.a <= x <= k11.c && k11.b <= y <= k11.d`，命中即 break。
3. `z2` = "起点落在任一存活内容边界之内"。
   **`if (!z2) xgbVar3 = new xgb(999999L)`（u5j.java:651-653）**：
   起点在内容之外 → zIndex=999999；命中或页面缺失 → 保持 null，
   解码端回退 `operation.clientTime`（顶层单调序）。

`xgb` 就是 zIndex：`dm2.toString`（dm2.java:235）把 `B()`（long 字段）
打印为 `zIndex=`；`cfc` case9（TO_FRONT）自 `max+1` 递增赋值、case8
（TO_BACK）自 min 起赋值 —— z 轴越大越靠前，故 999999 相对
clientTime（~1.7e12）恒为**衬底带**。

净效果：荧光笔在空白处起笔 → 永久钉在 999999，低于所有常规内容；
在既有内容上起笔 → 正常 clientTime 顶层。

`u5j.j`（u5j.java:720-824，CreateShape/`ao2` 生产者）携带同一探针
（`!z4 → xgb(999999L)`，:820-822）。`g1f.b`（g1f.java:132）对
`khd` 高亮事件生成的荧光笔**矩形**（`vaj.a` rect 路径）显式传
`new xgb(999999L)` 绕过探针 —— 999999 是原版的规范高亮衬底值。

## Harmony 对齐点

`StrokePersistence.ets:6697` `originalHighlighterUnderlayZIndex`：
`renderSpec.isHighlighter` 门 + 起点（`transform * pathPoints[0]`）
对每个存活元素 `bounds` 做同一闭区间测试；未命中返回 `'999999'`，
命中/非荧光笔/空路径返回 `undefined`（编码端不写 zIndex →
`OriginalCreateInkOperation.ets:164` 以 `operation.clientTime` 兜底，
与原版 null→clientTime 同约）。挂接点：`writeOriginalCreateInk`
（StrokePersistence.ets:3510）——本地画线提交的唯一 CreateInk 编码点。

## 有意不移植

- `u5j.j` 形状侧探针：原版探针在打点形状时源 Ink 仍在文档内（op 列表
  先于应用求值），形状原点必落在源 Ink 边界内 → 结果恒为 clientTime；
  Harmony 形状识别在同一保存内替换源 Ink，`current` 天然不含它，
  两种实现同结果 → 不引入探针以免在 `current` 缺源笔画时分叉。
- `g1f` 生成式高亮矩形：Harmony 无文本/PDF 选区→高亮矩形的入端，
  `originalSmartHighlight` 字段仅随形状往返，无可对齐表面。

## 回放

`docs/migration/replays/d04-original-highlighter-underlay-z.mjs`
（29 断言：原版结构断言 + Harmony 挂接断言 + 探针语义功能仿真）。

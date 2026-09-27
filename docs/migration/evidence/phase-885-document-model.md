# Phase 885 证据 — `x09`/`a79` 物化文档模型

## 目的

登记 u5j 工厂所消费的文档模型：`x09` 接口与 `a79` 物化
实现（`decompiled_1.0.3`）。

## `x09` 接口

仅伴生 `m09.a`——标记型接口；工厂实际消费 `a79` 具体字段。

## `a79 implements x09` = 物化文档模型

### 八寄存器 + 七具名属性（KProperty 实证）

`t..A: yc6` 八个 LWW 寄存器宿主；`M` 合成属性数组实名七项
（= `l2d` SET_METADATA 元数据面）：

| KProperty | 对应 l2d 槽 |
|-----------|-------------|
| title | z2d 标题 |
| defaultFontFamily | z2d 字体族 |
| defaultFontSize | Float 字号 |
| alignTextToLines | Boolean 对齐行 |
| layoutMode | tv6 布局模式 |
| blockWrapSupport | dz0 块环绕 |
| handwritingLanguage | String 手写语言 |

`K: nz9` = **note 级背景寄存器**：`(nz9) yc6Var7.K` winner，
缺省 = `Q`（默认纸面）——第八寄存器即背景 LWW。

### 其余字段

- `b: ye9` note 上下文；`f: f1a` **序列/实体模型**：
  `{b:rvb(svb 序源), c/h:cl2 表, d:kia, e/i:oja, f/j:q07,
  a/g:int}`——`bfj.b(f1a.b, i, f1a.h)` 的锚点。
- `B: m4c` = RichTextImpl 物化态（864）。
- `c: kia`、`d: Set`、`e: ArrayList`、`h: Map`、`i: List`、
  `k/l/m/n/o..s` = cl2/mja/hja/qja/bja/uia——实体索引集合族。

### 静态默认（实证值）

| 常量 | 值 | 语义 |
|------|-----|------|
| N | `qed(612,792)` | **US Letter 8.5×11pt** 默认页尺寸 |
| O | `fsi.f(36,36,36,36)` | 36pt 四边默认边距 |
| P | `N.d()/8.5` = 72 | 每英寸点数（pt/inch 换算） |
| Q | `vv7.f(tu1.a 色纸,…,N,…,54)` | 默认页背景（纸面） |
| L/R | `er6(3)`/`w69` | 杂项 |

## Harmony 侧

- `OriginalNoteBundlePageIdentity` 物化 note 态 ↔ a79；
  SET_METADATA winner 字段 ↔ 七具名属性寄存器（864/866）。
- 默认页尺寸/边距/背景 ↔ `PageBackgroundModel`/`NoteTypes`
  中的 Letter 默认（612×792、36pt 边距）。
- `f1a` 序模型 ↔ 物化页序 + 删除感知定位（880）。

## 结论

文档模型实名：a79 = 八 yc6 寄存器（七具名属性+背景）+
f1a 序模型 + 实体索引族 + Letter 纸默认。Harmony 对应
模型与默认等价。纯文档+fixture 阶段。

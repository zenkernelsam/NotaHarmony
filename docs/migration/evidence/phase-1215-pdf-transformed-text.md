# Phase 1215 证据 — pdf = TransformedTextFieldState（实名泄漏）

来源：`defpackage/{pdf,ps3,na3}.java`。

## toString 实名泄漏

```java
toString() = "TransformedTextFieldState(
    textFieldState=" + this.a +           // qoe = TextFieldState
    ", outputTransformation=" + this.d +  // ov1 = OutputTransformation
    ", outputTransformedText=" + this.e + // na3 e
    ", codepointTransformation=" + this.c+// ps3 = CodepointTransformation
    ", codepointTransformedText="+this.f +// na3 f
    ", outputText=" + d() +               // ele
    ", visualText=" + f() + ")";          // ele
```

## `pdf` = 变换文本域态（Compose `TextFieldState` 体系）

| 成员 | 真实角色 |
|---|---|
| `qoe a` | **TextFieldState** — 文本域态（undo/编辑会话） |
| `ov1 d` | **OutputTransformation** — 输出变换（掩码/格式） |
| `ps3 c` | **CodepointTransformation** — 码点变换 |
| `na3 e/f` | 变换后文本 `MutableState`（`extends osd`） |
| `d()→ele` | `outputText`（提交层文本） |
| `f()→ele` | `visualText`（显示层文本） |
| `g(i)/h(j)/i(j)→long` | output↔visual 偏移映射 |

`ps3 implements ssd,tf2,cs7,os2,wb,qw5,iv6,jkd,c0a,wec`
= Compose 文本变换复合 iface。

## 文本提交流程

```java
static k(pdf,cs,z):    插入文本提交
static l(pdf,str,j,z): 定位替换提交
a():                   会话结束提交
// 都经 qoe.b(dle) 构造编辑 → qoe.a(…,bme) 应用
//   → qoe.f(true) 标 undo 边界
```

`qoe.f(true)` = **undo 边界标记**（Phase 1190 `nnf`
对齐 —— 每个提交点产生一个可撤销单元）。

## Harmony 决策

`TransformedTextFieldState` → Harmony `TextEditState`：
output/visual 双文本 + 偏移映射 + 提交边界 —
ArkUI `TextInput`+`TextController` 需自研变换层
（格式化/掩码显示）。

## 产出

- fixture `d02-pdf-transformed-text.mjs`（10 断言）。
- ADR-1159；中文报告。

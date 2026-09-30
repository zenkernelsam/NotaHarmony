# Phase 1218 证据 — joe = TextFieldSelectionManager（实名枚举）

来源：`defpackage/{joe,mse,zne,r95,zn9,tr1,k6f,n8e}.java`。

## 实名枚举（枚举值泄漏）

| 类 | 枚举 | 值 |
|---|---|---|
| `mse` | **HandleState** | `None / Cursor / Selection` |
| `zne` | **PasteState/ToolbarMode** | `None / Touch / …` |
| `r95` | **Handle 类型** | `Cursor / SelectionStart / SelectionEnd` |
| `zn9` | Offset | `0x7FF8000000000000` = **Offset.Unspecified** |

## `joe` 状态面（TextFieldSelectionManager）

```java
p6a k = true;                        // enabled
p6a n,o = zn9(Offset.Unspecified);   // ← 手柄位置×2!
p6a p = null;                        // hover
p6a q = zne.I;                       // toolbar/paste 态
p6a r,s = mse.I;                     // HandleState
na3 x = fsi.x(xs0(this,3));          // 派生态
boolean d;                           // 编辑态
pdf a; ype b; k6f e; hi2 f; yla g; tr1;  // 文档/工具/IME/
                                          // 焦点/haptic
```

## `joe.A(ff2)` = IME 会话监视协程

```java
while (...) {
    y(false);
    if (mode != mse.I && (eje = k6f.a) != null
        && (tqd = eje.c0) != null) …   // IME session job 等待
}
```

`k6f.a`→`eje` 会话/`tqd` Job —— 键盘显隐时序。

## 选区 API

- `c(wpe,ele)→cmb` = 光标矩形；
- `D(ele,i,i2,z,gqc,z2,z3,xc5)→long` = 词/选区解析；
- `e(z,n8e)` = 选择动作（选区子序列→`a00`）；
- `C(r95,long)` = **手柄拖动**（`r95` Cursor/Start/End +
  位置）。

## Harmony 决策

TextFieldSelectionManager → Harmony 选区管理组件
（`zn9` 未定位 Offset + `mse`/`r95` 手柄态 +
`tr1` haptic→`vibrator` + IME 会话监视）。

## 产出

- fixture `d02-joe-selection-manager.mjs`（10 断言）。
- ADR-1162；中文报告。

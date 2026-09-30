# Phase 1205 证据 — vle 键盘/IME 集成层

来源：`defpackage/{vle,dli,hld,v52,etd,t52}.java`。

## `vle.o(KeyEvent)` = Back 键提交语义

```java
public final boolean o(KeyEvent keyEvent) {
    if (jqe.d(pdfVar.f().L) || !dli.a(keyEvent)) return false;
    // dli.a = keyCode==4 (KEYCODE_BACK) && action==1 (UP)
    qoe qoeVar = pdfVar2.a;                 // undo 会话
    qoeVar.b.a().w();
    dle dleVar = qoeVar.b;
    int i = (int)(dleVar.M & 0xFFFFFFFFL);   // 光标低位
    rfi.d(dleVar, i, i);                     // 选区坍缩至光标
    qoe.a(qoeVar, a46Var, true, bme.I);      // 提交待决编辑
    qoeVar.f(true);
    joeVar.y(false);                         // 退出编辑态
    joeVar.z(mse.I);                         // 模式复位
    return true;                             // 消费 Back
}
```

= **编辑中按 Back → 提交待决 IME 组合文本 +
选区坍缩 + 退出编辑模式**（消费掉 Back，不退出页面）。

## `vle.o1()` = 软键盘控制器查找

```java
hld o1() {
    hld v = aa6.v(this, v52.r);
    if (v == null) o14.l("No software keyboard controller");
    return v;
}
```

`hld` = 空标记 iface（软键盘控制器）；`v52.r =
new etd(t52.J)` = **服务定位令牌**（`aa6.v` 按令牌
在 ViewModel 树中查找控制器）。

## `vle.p1(boolean)` / `r(mv6)` / `t0()`

- `p1(z)` = `xj2.A(U0(),…,new sle(this,…))` 启动协程 —
  键盘显隐（`sle` 协程体）。
- `r(mv6)` = 空实现（`kv6` 的 no-op 事件槽）。
- `t0()` = `ijg.g0(this, new ple(this,1))` 派 `ple` 动作。

## Harmony 决策

- Back 提交语义 → Harmony `onBackPressed` 拦截：
  编辑态时提交待决输入 + 退出编辑（不导航）。
- `hld`/`etd` 服务令牌 → Harmony `@Provide/@Consume`
  或显式控制器注入。
- 软键盘控制 → Harmony `inputMethod` 模块。

## 产出

- fixture `d02-vle-keyboard.mjs`（10 断言）。
- ADR-1149；中文报告。

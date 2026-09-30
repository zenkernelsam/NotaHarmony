# Phase 1221 证据 — IME/软键盘层（in6/el8/yla/k6f/eje/qie/yie）

来源：`defpackage/{in6,el8,hi2,yla,k6f,eje,qie,yie,zie}.java`。

## 组件

| 类 | 角色 |
|---|---|
| `in6` | `void a(rle)` — 动作派发 iface（软键盘事件投递） |
| `el8 extends s7d,ol4` | Flow+Collector 汇（`emit`/`a()` — 键盘可见性流） |
| `hi2` | 标记 iface（回调注册键） |
| `yla` | **平台键盘控制器** — `{yh2 a, Context b, dqc c, fn7 d, em8 e=fm8.a() MutableSharedFlow, p6a g=null, Object h}` |
| `k6f` | **IME 会话持有** — `eje a`；`a()`→`rad` 协程显键盘 |
| `eje extends n73 implements q52,qie` | **软键盘 Modifier.Node** — `m(mv6)`/`q(mv6)` 几何 + `V` 可见 + `c0` Job + `Y0`/`Z0` |
| `qie` | 会话 iface（TextInputSession-like） |
| `yie` | 平台输入控制器 iface（`y52 b` companion；`aa6.v(eje, zie.b)` 令牌查找） |

## `k6f.a()` = 显键盘时序

```java
if (eje == null || !eje.V) return;
if ((eje.c0 == null || !c0.c()) &&
    (yie = aa6.v(eje, zie.b)) != null)
    eje.c0 = xj2.A(eje.U0(),…,ki2.L,
        new rad(5,null,eje,yie), 1);   // 显键盘协程
```

`zie.b` = 服务令牌；`yie` 经节点树服务查找获得。

## 判定

软键盘栈 = `eje` 键盘节点（`qie` 会话 + `q52` 选择
联动 + `m`/`q` 布局几何）+ `k6f` 会话持有 +
`yie`/`yla` 平台控制（Context+SharedFlow）+ `in6`
派发 + `el8` 流汇 —— Compose `PlatformTextInput`/
`TextInputSession` 体系。

## Harmony 决策

`PlatformTextInputSession`/`k6f`/`yie` → Harmony
`inputMethod` 模块（`showKeyboard`/`hideKeyboard` +
`@Watch` 可见性）；`yla` Context → `UIContext` 服务。

## 产出

- fixture `d02-ime-layer.mjs`（10 断言）。
- ADR-1165；中文报告。

# Phase 1269 证据 — wc5/hi2/el8/in6/of1/n03 编辑器依赖面

来源：`defpackage/{wc5,hi2,el8,in6,of1,n03}.java`。

## `wc5` / `hi2` = 平台服务 iface

`joe`(TextFieldSelectionManager) 依赖 —— `wc5` 对应
**ClipboardManager**（复制/粘贴读剪贴板）；`hi2` 对应
平台配置/会话服务（selection 语境）。

## `el8 extends s7d,ol4` = 流发射器

`emit(obj,ef2)` + `f(obj)→bool tryEmit` + `a()` —
— 非 `t76` 的事件流发射器（编辑器内部通知通道）。

## `in6` = 单方法监听器

`{void a(rle)}` —— 焦点/会话监听（`vle` ctor 依赖）。

## `of1` = 6-float 装饰器规格 + @Composable 工厂

```java
of1{float a..f};            // 滚动条/装饰尺寸规格
wrd a(boolean, wj8, t42, i) // → wrd Modifier
    // uz4 Composer + fsi.T remember + gl8/yk3
```

→ **滚动条/滚动装饰 Modifier 工厂**（wj8=事件流注入）。

## `n03` = 5-capture combine 流收集器

`{ol4,ft9,tr2,gv,mnb}` + `emit` —— `combine`/`onEach`
合并多流后输出。

## 语义

`vle`/`joe` 剩余依赖面 —— 剪贴板/服务 iface、事件流
发射器、焦点监听、滚动条装饰工厂、流合并收集器 —
— 编辑器外围服务完整接线。

## Harmony 决策

ClipboardManager→`pasteboard`；流发射器→`emitter`/
SharedFlow；滚动条→`ScrollBar`/装饰器 —— 外围服务
语义保真。

## 产出

- fixture `d02-editor-deps.mjs`（10 断言）。
- ADR-1213；中文报告。

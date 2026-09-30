# Phase 1200 证据 — 编辑器能力接口面（vle 11 iface）

来源：`defpackage/vle.java` + 11 公共接口。

## `vle` implements 11 编辑器能力接口

```
lo3   — extends j73; R(); x0(jw6)   // 生命周期+命令
cma   — (编辑域)
mvc   — default 方法
o65   — f(ry8)
ara   — default 方法
jm6   — (输入/笔迹域)
q52   — (选择/命中域)
rd8   — default 方法
sn9   — t0()
kv6   — b(long)
mp4   — (工具/状态域)
```

全 `public interface` —— 编辑器公共契约**按能力拆 11
接口**（笔迹编辑/文本/选择/媒体/undo/平移/缩放/工具/
页面导航等能力簇），`vle` 单类实现全 11。

## 判定

编辑器 API 面 = **能力接口分组**：`vle`（编辑器
ViewModel）通过 11 接口暴露编辑能力给 Compose UI —
`lo3/cma/mvc/o65/ara/jm6/q52/rd8/sn9/kv6/mp4` 对应
笔迹/文本/选择/媒体/undo/视图/工具等编辑域。

## Harmony 决策

- 11 能力接口 → Harmony 编辑器组件的方法组（interface
  `EditorController` 分能力子集，或 ArkUI 组件方法）。
- `vle` 单实现 → Harmony 单 editor 控制器（`@Observed`）。

## 产出

- fixture `d02-editor-iface.mjs`（10 断言）。
- ADR-1144；中文报告。

# Phase 838 — 深链 `<data>` 面闭合

证据：三版 manifest `<data>` 元素全量解析 + Harmony
`module.json5`/`DeepLinkIngress.ets` 对照

## 一、URI 模式清单

| scheme | host | path | 版本 |
|--------|------|------|------|
| http/https | notability.com + `*.notability.com` | `/authlink`(prefix) | 全版 |
| 同上 | 同上 | `/app/note`(prefix) | 全版 |
| 同上 | 同上 | `/gallery`(prefix) | **1.4.2 新增** |
| 同上 | 同上 | `/event/learn-from-home`(/) | 全版 |
| 同上 | 同上 | `/event/plus25`(/) | **1.0.3 新增** |
| 同上 | 同上 | `/event/planner2627`(/) | **1.4.2 新增** |
| `content`/`file` | — | —（attachment VIEW/SEND） | 全版 |
| — | — | `application/pdf` MIME | 全版 |
| `msauth` | com.gingerlabs.notability | —（MSAL 回跳） | 全版 |

## 二、版本谱系

- 1.0.1：authlink + app/note + learn-from-home；
- 1.0.3：+ `/event/plus25`；
- 1.4.2：+ `/event/planner2627` + **`/gallery`**（pathPrefix，
  与 792 画廊簇同期）。

## 三、关联解码：`MainActivity.n(configuration)`

```java
public final void n(Configuration configuration) {
    Rect bounds = getWindowManager().getCurrentWindowMetrics().getBounds();
    ui9Var.c.l(null, new mi9(new Configuration(configuration), new Rect(bounds)));
}
```

configChanges 处理实际语义：**把 (Configuration + 窗口边界) 推入
`ui9.c` 流**——自适应布局引擎的配置事件流（multi-window
置顶回调 `onTopResumedActivityChanged` 亦走此）。

## 四、Harmony 侧

- `module.json5` uris：仅声明 `app/note`（http/https ×
  notability.com）+ file/pdf——`/gallery`/`/authlink`/`/event/*`
  **未声明**（通配子域亦不支持），均 fail-closed 登记；
- `DeepLinkIngress` 注释漏 `/gallery` 与 `/event/planner2627`——
  **本相位修正注释为完整清单**；
- `msauth`：MSAL 回跳专属，Harmony 无对应（登记）；
- `n()` 配置流：Harmony `onConfigurationUpdate` 已有等价
  （ThemeStore.setSystemDark），布局重算由 ArkUI 自适应承担。

## 五、结论

深链面按版本谱系闭合；`/gallery`+`planner2627` 为 1.4.2 新增
已登记；configChanges 语义补完（配置+边界→布局事件流）。

# 原版「Add GIF」Klipy 联网挑选 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「插入菜单 Add GIF → Klipy 挑选 → IMAGE
元素」链路的静态证据，支撑 Phase 659 的结构性 fail-closed 登记。

## 菜单项与旗标

- `qc.java` case 0：`if (function4 != null)` 才渲染
  `feature_note_toolbox__add_gif`（第 4 序位，Math 之前）。
- `u49.java`：回调 `function21 = new qb5(gl8Var10, 23)` 仅在
  `lc4.a(ac4.k0)` 为真时构造；`ac4.java:138` `k0 = new
  ac4("ANIMATED_IMAGES", 25, ...)` —— **特性旗标门控**。
- `gl8Var10` 为 GIF 挑选页 sheet 状态；`u49:1654+` 的
  `gl8Var10.getValue()` 分支渲染挑选页（`rd9Var3` → `w43`/`q49`/
  `ft0` 处理器 → `vc2`/`u22`/`ar4` 组合）。

## Klipy SaaS 依赖

`f65.java:26`：

```java
sb.append("https://api.klipy.com/api/v1/<64字符客户密钥>/gifs/");
sb.append(str);                       // trending / search 等端点段
sb.append("?per_page="); sb.append(i);
sb.append("&locale="); sb.append(locale.getLanguage() + '_' + country);
if (str2 != null) { sb.append("&q="); sb.append(URLEncoder.encode(str2)); }
```

- 端点为 `api.klipy.com`（Klipy 第三方 GIF 搜索 SaaS），**API 密钥
  硬编码在 URL 路径中**——属于原版厂商的付费服务凭证。
- 字符串资源佐证：`feature_note__gif_picker_attribution` =
  "Powered by Klipy"，另有 empty/error/retry/search_hint/
  item_description 全套挑选页文案。
- `u22` 渲染搜索框（search_hint），`ar4` case 1 渲染 `p55` 网格项
  （`elh.a` 图片 + `gd2(ix4, p55, gl8, 3)` 选中回调，带防重复点击）。

## 选中物化（p55 → re0 → bgj.b）

- `p55` = `GifItem(previewUrl, fullUrl, width, height)`。
- `ft0` case 855+：`xj2.A(rd9.h(), null, null, new js7(21, ef2, rd9, p55))`
  —— 选中进协程。
- `js7` case 21 → `re0` 变体（`re0.java:192+`）：
  1. `File.createTempFile("gif_", ".gif", cacheDir)`；
  2. 从 `p55.b`(fullUrl) 流式下载，`fag.z(in, out, 104857600L)` —
     **100MB 上限**，超限 `"GIF exceeded max insert size"` + 删除；
  3. `je4(name, "image/gif", length, apb.h(w,h))` FileInfo 描述符；
  4. `bgj.b(x09, fileInputStream, je4, cxc, j, p29, f, ff2)` → `rl2`。
- `bgj.java:70+`：`bvh.a` 几何（fit-to-page + 320pt/f 上限）定位后
  构造 `cz0.IMAGE` 元素 —— 与图片插入同一物化形态，mime=image/gif。

## 结论

Add GIF = **Klipy 联网 GIF 搜索挑选**（动画图插入 IMAGE 元素）。
HarmonyOS 无 Klipy SDK，复制原版厂商 API 密钥亦不可取；原版无本地
GIF 插入替代路径（菜单项本身即 Klipy 挑选页）。登记结构性
fail-closed（ADR-0626）。本地 `.gif` 文件经 Add Files 已可导入为
IMAGE 元素（Phase 653/657/658），动画表现由渲染层另案评估。

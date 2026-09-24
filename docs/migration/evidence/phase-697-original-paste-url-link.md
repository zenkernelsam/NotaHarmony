# Phase 697 — 原版粘贴 URL 自动转链接（fm7.j/jvi.d）Evidence

## 范围

原版富文本编辑器的粘贴管线 `fm7.j()`：粘贴板纯文本 trim 后若为
URL，规范化并以链接样式插入；Harmony 文本块编辑覆盖层此前走
TextArea 原生粘贴（纯文本插入，丢失链接语义）。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/fm7.java` —— `j(tr1, ff2)`

```java
// 取剪贴板首项纯文本
String string = w7j.b(rr1Var.a()).getText().toString();
// lvd.d1 = trim（去首尾空白）
String string2 = lvd.d1(string).toString();
// jvi.d = URL 规范化（见下）；命中则构造 zyd{h: normalized}
if (string2 != null && (strD = jvi.d(string2)) != null) {
    zydVar = new zyd(null, ..., strD, ..., 1919);
}
if (zydVar != null) {
    string = string2;            // 可见文本换成 trim 后版本
}
this.c.U("pasteFromClipboard", new p7(zydVar, this, string, 28));
```

要点：
- 命中 URL 时**可见文本 = trim 后字符串**，链接值 = 规范化 URL。
- 未命中时粘贴**原始**（未 trim）字符串，无样式。

### 2. `sources/defpackage/jvi.java` —— `d(String)`

```java
if (URLUtil.isValidUrl(str) || Patterns.WEB_URL.matcher(str).matches()) {
    scheme = Uri.parse(str).getScheme()?.toLowerCase();
    if (scheme == null)  return "https://" + str;   // 无 scheme 补 https
    if (scheme in {http, https}) return str;         // 原样
}
return null;                                          // 其余拒绝
```

净语义：只放行 http/https 完整 URL 与"无 scheme 的 web URL"
（`Patterns.WEB_URL` 类：`www.x.y`、`x.y/path` 等）。

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| 粘贴入口 `fm7.j()` | `TextArea.onPaste((value, event) => onTextPaste(...))` |
| `lvd.d1` trim | `value.trim()` + `/\s/` 内嵌空白拒绝 |
| `jvi.d` URL 判定 | `pastedUrlOrNull`：显式 scheme → 仅 http/https 且 host.tld 形态；无 scheme → `(www.)?host.tld[:port][/path]` → 补 `https://` |
| URL 命中 → 自定义插入 | `event.preventDefault()` 取消原生粘贴 + 选区替换 trim 文本 + `applyLinkUrl`（P692 管线）+ `normalizeCharRuns` |
| 非 URL → 原生粘贴 | 直接返回，原生 TextArea 粘贴继续（onChange 差分平移已有） |
| 粘贴后光标 | `controller.caretPosition(s + title.length)` |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-paste-url-link.mjs`：
  19 项静态钉全绿。

# Phase 697 — 原版粘贴 URL 自动转链接（fm7.j/jvi.d）移植

## 范围

`fm7.j()`/`jvi.d`：粘贴纯文本若为 URL，自动以链接样式插入——
此前 Harmony 端走 TextArea 原生粘贴，链接语义丢失。

## 原版行为（证据见 phase-697 evidence）

- 剪贴板首项纯文本 → `lvd.d1` trim → `jvi.d` URL 判定。
- 命中：可见文本换成 trim 后字符串，`zyd.h` = 规范化 URL
  （无 scheme 补 `https://`，http/https 原样，其他 scheme 拒绝）。
- 未命中：原始字符串纯文本粘贴。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `onPaste` → `onTextPaste`：`pastedUrlOrNull`（jvi.d 等价——
    显式 scheme 仅放行 http/https + host.tld 形态；无 scheme 要求
    `host.tld[:port][/path]` 并补 `https://`）命中时
    `event.preventDefault()` 取消原生插入，选区替换为 trim 文本 +
    `applyLinkUrl` + `normalizeCharRuns`（复用 P692 链接管线），
    `caretPosition` 落尾 + `onDraftChange`。
  - 非 URL：直接返回 → 原生粘贴继续（`onChange` 差分平移已覆盖）。
  - `photoImportLeaseActive` 期间不拦截。

## 验证

- Replay：`d02-original-paste-url-link.mjs` 19 项全绿；
  lease-bound 计数不变。
- 构建：`note@ohosTest`/`note@default` clean assembleHap 成功。
- 真机/模拟器：未验证（约束内）。

## 限制

- `Patterns.WEB_URL`/`URLUtil.isValidUrl` 的完整字符集规则比
  移植正则宽（IDN、罕见 TLD、IPv6 host 等边角形态未覆盖）——
  边界 URL 会退化回纯文本粘贴（fail-open，不丢内容），登记差异。
- 粘贴 URL 的 trim 行为与原版一致；多行含 URL 文本不触发链接化
  （原版 `Patterns.WEB_URL.matches` 要求整体匹配，行为一致）。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-paste-url-link.mjs`

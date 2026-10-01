# Phase 1416 证据：窄屏库 chrome 与文件夹对话框无障碍语义

- 版本证据基线：`decompiled_1.4.2`
- 接续 Phase 1415：onboarding 链收尾后，清理由此暴露的窄屏库 chrome
  无障碍差距（虚构串 `open_folder_drawer`、缺 `close_drawer` 遮罩语义、
  文件夹对话框无专用 cd）。

## 1. Hamburger「Organize」钮（mf2 case21 → i87.b）

| 原版 | 语义 | 证据 |
|------|------|------|
| `mf2` case21 | `i87.b(yb0.A(R.drawable.ui_designsystem__hamburger), oye.w0(nc6Var22, R.string.ui_librarypane__cd_organize), null, 0L, nc6Var22, 8, 12)` —— 图标钮 cd = "Organize" | `mf2.java:410` |
| `ail.a` | 该 lambda 注册为共享 `jf2`（`new jf2(672604807, false, new mf2(21))`） | `ail.java:9` |
| `ihm.a` | `wv9.b(t0c.R, 2, z2, …, k31.L(-897645436, new z8(function0,(byte)28)))` —— 把该钮包进 COMPACT_ORGANIZE（槽位2=锚点下方）引导锚点；宿主 `l86`/`vkm` | `ihm.java:32`、`l86.java:97`、`vkm.java:665` |

→ Harmony `LibraryPage` 窄屏头部 hamburger 钮原挂虚构串
`open_folder_drawer`；改挂 `ui_librarypane__cd_organize`，COMPACT_ORGANIZE
`bindPopup` 锚点不变。

## 2. 文件夹名钮无专用 cd

`vkm` compact 头部在 `ihm.a` 之后接 `vkm.i`（含两个 `f8n.a` 图标钮与
nil.a 内容），未见文件夹名专用 cd —— 名钮以文本自标识。
→ Harmony `Button(this.currentFolderName())` 移除虚构
`open_folder_drawer` 覆盖，回到自标识。

## 3. 抽屉遮罩「Close navigation menu」（fla）

| 原版 | 语义 | 证据 |
|------|------|------|
| `fla` | ModalDrawer 骨架：`strD = ofk.D(nc6Var, R.string.close_drawer)`；遮罩 `nfh.b(w8aVarB2, function0, PointerInputEventHandler)`（点击关闭）+ `tuf.b(…, true, s7a(strD, function0))`（语义=cd） | `fla.java:1331-1350` |
| `close_drawer` | `"Close navigation menu"` | `strings.xml:74` |
| 宿主 | `cla` → `fla.b`（ModalNavigationDrawer） | `cla.java:45` |

→ Harmony 遮罩 `Column().onClick(close)` 补
`.accessibilityText(close_drawer)`；点击关闭语义既有。

## 4. 文件夹对话框（ybn）

| 原版 | 语义 | 证据 |
|------|------|------|
| `ybn` 名称框 | `strW2 = w0(ui_folder__cd_folder_name)`；`tuf.b(w8aVarL, r6, hd(strW2))` 把 "Folder name" 挂进 TextField 语义 | `ybn.java:1041-1052` |
| `ybn` 确认钮 | `hdcVarA2 = yb0.A(general_check_med_bold)`；`strW1 = w0(ui_folder__cd_confirm)`；`cc3.l(hdcVarA2, strW1, …)` —— check 图标钮 cd = "Save folder" | `ybn.java:912-928` |

→ Harmony 文件夹对话框 `TextInput` 补
`accessibilityText(ui_folder__cd_folder_name)`；确认 `Button`
（保留既有 "Confirm" 文本视觉）补 `accessibilityText(ui_folder__cd_confirm)`
—— a11y 宣告 "Save folder" 与原版一致。

## 5. 移除项

`open_folder_drawer`（"Open folders"/"打开文件夹"）为 Harmony 虚构串，
本 Phase 后无任何引用，随本次删除（同 Phase 1412 `connect_action`
先例）。

## 6. Harmony 实现映射

| 原版 | Harmony | 状态 |
|------|---------|------|
| hamburger cd = cd_organize | `.accessibilityText($r('app.string.ui_librarypane__cd_organize'))` | ✅ |
| 遮罩 cd = close_drawer | 遮罩 Column `.accessibilityText($r('app.string.close_drawer'))` | ✅ |
| 名称框 cd = cd_folder_name | `TextInput.accessibilityText($r('app.string.ui_folder__cd_folder_name'))` | ✅ |
| 确认钮 cd = cd_confirm | `Button(confirm).accessibilityText($r('app.string.ui_folder__cd_confirm'))` | ✅ |
| 名钮自标识 | 移除 `open_folder_drawer` 覆盖 | ✅ |

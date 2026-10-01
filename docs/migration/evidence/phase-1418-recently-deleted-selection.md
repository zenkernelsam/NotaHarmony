# Phase 1418 证据：原版 Recently Deleted 选择制界面

反编译基线：`decompiled_1.4.2`（`sources/defpackage`、`resources/res/values`）。
本节钉住"最近删除"设置页的**选择制**信息架构——Harmony 此前实现
为逐行 Recover/Delete 按钮，与原版模型不符（其自带空态文案
"Select notes to add them back…" 即已暗示选择制）。

## 1. 模型：`p6e.invokeSuspend` → `a6e`

`p6e`（`ps2` VM 的流合成器）把 `Map<w9b,ycb>`（回收站笔记）+
`Set`（选中集）+ 两个 boolean 合成一个 `a6e`：

```java
epe epeVar = new epe(zx7.r(set, map.keySet())
    ? R.string.feature_settings__deselect_all
    : R.string.feature_settings__select_all);
d8d d8dVar = set.isEmpty() ? null
    : new d8d(R.plurals.feature_settings__notes_selected, set.size(), …);
boolean z3 = !set.isEmpty();                              // 批量动作使能
d8d d8dVar2 = !z ? null
    : new d8d(R.plurals.feature_settings__delete_confirmation_message,
              set.size(), …);
… pa9VarE2.add(new z5e(bpjVar, title-p0h,
    new epe(R.string.feature_settings__note_deleted_at, zq.M(j)),
    ycbVar.l(), ycbVar.k(), set.contains(w9bVar)));
return new a6e(epeVar, d8dVar, list, z3, d8dVar2, z2);
```

| `a6e` 字段 | 语义 |
|---|---|
| `.a` (`epe`) | "Select all" / "Deselect all"（`set == map.keySet()` 判定） |
| `.b` (`p0h`/`d8d`) | "N note(s) selected" 横幅，选集为空时为 null |
| `.c` (`pa9<z5e>`) | 行模型：`(bpj id, 标题, "Deleted %1$s", 图标, 色调, selected)` |
| `.d` (`z3`) | 选集非空 → 底部两个批量钮 enabled |
| `.e` (`d8d`) | 删除确认正文（`delete_confirmation_message` 复数 + 数量） |
| `.f` (`z2`) | 上限挽留（note-limit）相关 flag → 付费墙，fail-closed |
| `.g` | 列表空 → 底部条不显示 |

## 2. 顶部区：`wrl.i`

Column（`d0f`/`b0f`）内按序渲染：

1. `o9n.a(null, a6eVar.a.a(nc6Var), …, onClick = new w5e(bz5Var,(byte)5))`
   —— Select all / Deselect all 文本钮 → `j6e`（全选切换 UserAction）。
2. `x7n.e(strA != null, …, y8(strA,9))` —— `a6e.b` 非空时显示
   "N notes selected" 横幅。

## 3. 行：`th3` → `wrl.h`

`th3` 逐项渲 `z5e` 列表：

```java
wrl.h(w8aVarA, z5eVar.a /*bpj*/, strA /*title*/, strA2 /*meta*/,
      z5eVar.d, z5eVar.e, z5eVar.f /*selected*/,
      new oe(bz5Var, z5eVar, (byte) 24) /*点击*/, …);
```

`wrl.h` 内：

- `fq9.p(w8aVar, false, null, null, function0, 15)` —— 整行可点击，
  `oe(24)` 即 `bz5.invoke(new g6e(z5e.a))` = 按笔记 id 的选择切换。
- 行体 = `x8n.a(…, y8(str2) 前导图标, ibb 标题/副文,
  mo2(z,str,7) 复选框, gbb(str,8))`。

`mo2` case7 = `f9n.b(selected, title)` 复选框，语义标签：

```java
strV0 = selected
  ? oye.v0(R.string.feature_settings__cd_deselect_note_titled, title)
  : oye.v0(R.string.feature_settings__cd_select_note_titled, title);
```

—— 即 `cd_select_note_titled`/`cd_deselect_note_titled` 插值的是
**笔记标题**（`z5e` 标题字段，空标题已在 `p6e` 落到
`data_library_state__default_note_title`）。

## 4. 底部批量条：`v5e` case0（`wrl.g` → `x7n.e(!a6e.g)`）

列表非空时渲染两个 `o9n.a`：

```java
o9n.a(null, "Delete"(delete_notes), null, false, a6e.d /*enabled*/,
      mma.G /*危险色样式*/, …, new w5e(bz5Var,(byte)2));
o9n.a(null, "Recover notes"(recover_notes), null, true, a6e.d,
      null, …, new w5e(bz5Var,(byte)3));
```

`w5e`：`case2`/`case3` = 删除/恢复请求；`case5`=`j6e`（全选切换）；
`case0`/`case1` = 确认对话框 dismiss/confirm。

## 5. 删除确认：`wrl.b`（`d77` default）→ `l8n.c`

```java
l8n.c(onDismiss=w5e(0), "Delete"(delete_notes) /*确认钮文案*/,
      onConfirm=w5e(1), null, "Keep notes"(keep_notes) /*取消钮*/,
      null, true, content=gbb(7) /*正文 Text*/, …);
```

- 正文 = `a6e.e` = `feature_settings__delete_confirmation_message`
  复数：`"Permanently delete %1$d note?\nThis action cannot be undone."`
  / `…notes?…`。
- `str`/`str2` 槽位是**按钮文案**而非标题：`iqm.java:1140` 同函数
  以 `ui_fileimport__import`/`ui_fileimport__dismiss` 作确认/取消，
  可证原版对话框无标题位。

## 6. Fail-closed：上限挽留

`wrl.f`（`x7n.e(!a6e.g)` 内另一支）经 `l8n.e` 渲
`feature_settings__note_limit_recover_*` 对话框——恢复超过免费
上限时的付费挽留，属订阅/付费墙流程（`a6e.f` flag）。Harmony 版
无笔记上限模型，fail-closed；Recover 直接恢复。

## 7. 已判定不移植的同批候选

- `feature_note_toolbox__cd_hide_tools`：属原版 `vpm`/`qm8`
  主/副双条工具箱（`wpb=OnDisplaySecondaryToolsChange`，
  `hx7` 有 `"primaryTools"`/`"secondaryTools"` 区）。Harmony
  `EditorToolbar` 为单条横向 Scroll，无宿主——贴假标签即误导。
- `feature_note_toolbox__cd_audio_player_settings`：属原版 `kom`
  行内音频播放器 ⋯ 钮；Harmony 无该行内播放器宿主。
- `feature_note_toolbox__cd_playback_position`：属 `tfl` 行内
  播放位置滑杆语义；Harmony `RecordingPanel` 无等价滑杆。

## 8. 适配说明（非缺陷）

- `cd_delete_recording`：原版插值录音显示名（`kd6` `strV0`）；
  Harmony `Delete Recording %d` 与行标题 `Recording %d` 展开后
  播报文本等价——资源形不同而语义等价，记为适配。
- Harmony `select_all`（"Select all"）值与 `feature_settings__
  select_all` 逐字相同，直接复用；`deselect_all` 现存键值为
  "Deselect All"（`feature_library__` 变体），故按原名新增
  `feature_settings__deselect_all`="Deselect all"。
- 复数资源：Harmony SDK 仅暴露异步 `getPluralString`，沿用库页
  既有约定拆 `_one`/`_other` 两键按数量选择。

## 9. Replay

`docs/migration/replays/d02-original-recently-deleted-selection.mjs`：
52 项，钉住 `p6e` 模型字段、`wrl.i/h/b` 渲染、`v5e` 批量条、
`mo2`/`f9n.b` 语义、`w5e`/`j6e`/`g6e` 动作链、原版资源与 Harmony
实现及 fail-closed 标记。

# 原版编辑器「Add Files」插入既有笔记 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「编辑器插入菜单 → Add Files → 物化进当前
笔记」链路的静态证据，支撑 Phase 657。与 Phase 652-656 的独立导入共用
`jv5`/`cv5`/`dv5` 类型分发与 `yq8.f` 负载路由，差别仅在导入目标描述符。

## 插入菜单序位（qc.java case 0）

`decompiled_1.0.3/sources/defpackage/qc.java`（约 64-115 行）渲染插入菜单：

```text
apb.f(add_files   → sc(function0, dismiss, 0))
apb.f(add_photo   → sc(function2, dismiss, 1))
apb.f(take_photo  → sc(function3, dismiss, 2))
if (function4 != null) apb.f(add_gif   → sc(function4, dismiss, 3))
if (function5 != null) apb.f(insert_math → sc(function5, dismiss, 4))
```

- **Add Files 是序位第一**（此前 653 之前 Harmony 注释误记为
  Add Photo 第一，本阶段已更正）。
- `add_gif`/`insert_math` 均为条件项（callback 非空才渲染）。

## 三种导入目标（tv5 家族）

```text
qv5.toString  = AddToExistingNote(noteId=…)        // 插入既有笔记
sv5.toString  = CreateSingleNewNote(title=…, folderId=…)   // 652-655 已实现
rv5.toString  = CreateSeparateNotes(folderId=…, titleOverrides=…)
```

`yq8.g(ff2, tv5, list)`（`yq8.java:290+`）按目标分发：

- `tv5Var instanceof qv5` → `e(ttfVarA, list, xq8Var)` —— **未反编译**
  （837 指令跳过），但签名表明：对既有笔记 `ttf` 应用负载列表。
- `sv5` → `c(xq8Var, utf, title, list)`（建新笔记）。
- `rv5` → `b(list, utf, titleOverrides, xq8Var)`（每文件一笔记）。
- 任何负载为 `ru5`（NTB）时要求**全部**为 `ru5`
  （"NTB selection must be homogeneous"），走 `d(...)` 归档管线。

## 目标选择流（ou5 状态机）

`ou5` 是导入状态机（`o1.java`/`ub2.java` 为其合成 lambda）：

- `o1` case（`o1.java:406`）：`fu5Var instanceof st5` →
  `new qv5(((st5) fu5Var).a)` —— 选中既有笔记 → AddToExistingNote。
- `ub2` case 4（`ub2.java:222`）：`ou5.p(utf)` 选定笔记后
  `new qv5(ttfVar)`。
- `vs5`（`vs5.java:22`）：笔记列表回调 `invoke(new st5(ttfVar))`；
  `st5.a` 即目标笔记 `ttf`。
- `ss5`（`ss5.java:188/245`）：目标选择 UI（note 列表 + folder 列表）
  挂 `vs5` 回调。

## 结论

原版「Add Files」把文件经同一 `jv5` 类型分发物化为 `su5/qu5/tu5/pu5`
负载，再由 `yq8.g` 按 `qv5` 目标把 reducer ops 应用到**打开的笔记**——
即与 Phase 652-655 相同的四种物化形态，仅落点从「新笔记」变为「既有
笔记末尾」。`.note`（ru5）并入既有笔记的语义在 `yq8.d/e` 未反编译区，
无法证明等价，Harmony 侧 fail-closed（into-note 选择器不收 `.note`）。

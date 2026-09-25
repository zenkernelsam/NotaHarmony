# ADR-0656 「Inky」动画吉祥物模式 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：708
- 接续：ADR-0544（编辑器 ⋮ 选项菜单审计——已将 Inky 菜单项
  记为"无对应面"）、ADR-0626（Klipy/外部服务 fail-closed）、
  ADR-0652（Learn/AI 面 fail-closed）；本 ADR 把 Inky 从菜单
  审计附注升级为完整旗标→Rive 链 fail-closed 登记
- 证据：`docs/migration/evidence/original-inky-mode-jadx-2026-09-25.md`

## 背景

原版 `ac4.p0`（`INKY_MODE`，序号 31）控制 "Inky" 动画吉祥物
模式：`w16.java` 评估 `lc4.a(ac4.p0) && !z` → 工具栏状态
`t9f` 的 `inkyModeAvailable` 字段；选项菜单渲染
`feature_note__options_menu_inky`（"Inky"，`z22:354`）开关项 →
`l26`/`k26` `inky_mode_enabled` datastore 偏好 → `t9f.
inkyModeEnabled`。

开启后 `h26.java` 渲染 Inky 悬浮层：Rive 动画资源
`R.raw.feature_note_inky__inky_2026_v32`（res/raw 内 304 KB .riv
文件），经 `e5c.b(RiveFileSource.RawRes...)` 加载 +
`inkyAlpha` 渐变过渡。

## 决定

1. **不实现 Inky 模式**，登记结构性 fail-closed：Inky 呈现依赖
   **Rive 动画运行时**（第三方引擎 `.riv` 二进制格式）——
   Harmony 无等价运行时，自行实现 Rive 解码器超出本迁移范围。
2. **Harmony 不渲染 Inky 入口**：选项菜单无 Inky 开关、工具栏
   无 Inky 层——等价于 `ac4.p0` 旗标关闭态（`inkyModeAvailable
   =false` 的原版体验）。
3. **不涉及笔记数据**：Inky 是纯 UI 吉祥物层，`inky_mode_
   enabled` 仅为 UI 偏好，不影响任何笔记内容/ops——无数据面
   登记需求。

## 后果

- 原版旗标关闭用户体验 = Harmony 体验；
- 若 Harmony 生态出现 Rive 播放器或官方移植，本 ADR 可重开。

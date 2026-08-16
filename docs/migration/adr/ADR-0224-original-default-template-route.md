# ADR-0224：分离原版默认模板设置路由与编辑器纸张职责

## 状态

Accepted，2026-08-16。

## 背景

Phase 246 已恢复 `selectedDefaultTemplate` 的二进制存储和新笔记消费链，但当时把保存动作临时放进编辑器
`PageSettingsPanel`。继续追踪原版设置导航后确认：默认模板属于独立 `TemplateRoute/rge`；编辑器弹窗使用
`vge`，只修改当前笔记，根本不依赖 `o59.selectedDefaultTemplate`。

同时，原版 size/orientation 回调只修改 picker 草稿，用户点选模板卡时才组合并提交。Harmony 原实现每点一次
尺寸、模板或方向就立即关闭 popup 并持久化，入口所有权与交互顺序都不等价。

## 决策

1. 新增 `DefaultTemplatePage`，由 `SettingsPage` 的“Template”入口导航，并注册到 `main_pages.json`。
2. 默认页读取/保存继续复用 `EditorSettingsStore` 的 root `nz9` `Uint8Array`，不引入第二套偏好格式。
3. 编辑器 `PageSettingsPanel/PageManagerBar/NotePage` 删除写默认模板的 callback 和保存方法；编辑器只能提交
   note-level 背景 operation。
4. 新增纯 `OriginalTemplatePickerState`：size/orientation 先进入草稿；点 Plain/Lines/Grid/Dots 卡片时才生成
   要提交的 `NoteBackgroundSettings`。默认设置页与编辑器共用同一语义。
5. 同线型只改变尺寸/方向时保留现有 paper RGBA、spacing 与 legacy paper index；跨线型使用该线型内建
   36 pt spacing，直到共享 `BackgroundInfo` spacing 库完成移植。
6. 默认页保存采用 optimistic UI + flush 失败回滚，并提供 loading/error/retry/save-failure 状态。

## 结果

- 新笔记默认纸张有了与原版同层级的设置入口。
- 编辑当前笔记不会意外改变以后新建笔记的默认纸张。
- size/orientation 不再产生半完成的立即提交；模板卡是明确的提交边界。
- Phase 246 的二进制 wire/storage 契约保持不变。

## 未纳入本 ADR

- `BackgroundInfo` 收藏/取消收藏及去重；
- Plain/Lines/Grid/Dots 各自独立的 spacing 持久化；
- 原版纸张颜色选择器和 legacy paper 浏览；
- 设置页 list/detail 双栏适配的像素级复刻。

这些能力已有原版静态证据，但应作为后续独立阶段实现和验证，不能与本次入口纠错混成“已完成”。

## 验证

- 证据：`docs/migration/evidence/original-default-template-route-jadx-2026-08-16.md`。
- replay：`docs/migration/replays/d02-original-default-template-route.mjs`。
- ArkTS fixture：`OriginalTemplatePicker.test.ets`。
- 设备验收继续保留，未启动虚拟机、模拟器、真机或 Hypium。

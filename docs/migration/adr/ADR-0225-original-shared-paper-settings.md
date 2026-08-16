# ADR-0225：恢复原版共享纸张设置数据库、收藏与分线型 spacing

## 状态

Accepted — 2026-08-16，Phase 248。

## 背景

Phase 247 已恢复原版默认模板路由与“尺寸/方向暂存、点模板卡提交”的边界，但当时仍把以下能力明确列为
缺口：

- 设置页与编辑器共享的 PLAIN/LINES/GRID/DOTS 状态；
- Lines/Grid/Dots 各自独立的 spacing；
- 完整纸张组合的 favorite/unfavorite；
- 原版 Room schema 与 64 位 packed paperSize。

原版 1.0.3 不是把这些值写进 `selectedDefaultTemplate`。`BackgroundInfo` 按线型保存 spacing/hasOptions，
`PaperBackground` 保存完整 `l3a` 收藏；默认模板和当前笔记仍走各自原有提交链。

## 决策

### 1. 恢复原版两表并升至数据库 v63

在 NotaHarmony 主 RDB 内按原版列名和类型新增：

- `PaperBackground`
- `BackgroundInfo`

迁移 v62→v63 与最新 schema 创建列表都包含两表。选择共用现有主 RDB，是 Harmony 项目的单数据库适配；
表语义和职责保持原版，不把它们合并进 Preferences。

### 2. 建立独立纯模型与精确数值边界

新增 `OriginalPaperSettings.ets`：

- 四类原版线型和空表 fallback；
- 原版十档 Float32 spacing，UI 写入只接受十档；
- 读取兼容 nullable/legacy 正 Float；
- 完整 signed ARGB，包括 alpha；
- 八种 paperSize 的 packed SQLite INTEGER 映射；
- 收藏 equality 忽略 Room id，但比较其余完整语义。

packed paperSize 超过 JS 安全整数，因此以十进制字符串写入、以 SQL `CAST(... AS TEXT)` 读取；rounded
number 只作为只读兼容入口，绝不回写。

### 3. 所有共享纸张写入复用全局单写者与事务

新增 `OriginalPaperSettingsStore`，所有写入通过 `databaseWriteMutex`：

- PLAIN spacing 更新 no-op；
- 其他线型 insert-or-update，并保留已有 `hasOptions`；
- 收藏添加先按语义去重；
- 取消收藏先找到语义相同行，再用其真实自增 id 删除；
- update 要求持久 id 且影响行数必须为 1；
- 任一步失败整体 rollback。

### 4. 两个入口共享 Store，但不改变提交所有权

设置页和编辑器继续复用 `PageSettingsPanel`，因此加载同一 BackgroundInfo/favorites。组件会幂等初始化
`DatabaseManager`，不依赖此前某个页面已打开数据库。

职责保持：

```text
DefaultTemplatePage -> selectedDefaultTemplate
PageManagerBar      -> 当前笔记 NOTE_BACKGROUND
PageSettingsPanel   -> BackgroundInfo/PaperBackground
```

spacing 的修改只落共享表；用户仍需点击模板卡，才把该 spacing 与尺寸/方向组合后提交到默认模板或当前笔记。

### 5. Slider 使用连续预览、最终值提交

原版 Compose callback 会随拖动产生值；直接在 ArkUI 每次回调设置全局 busy 会丢掉后续及最终落点。因此
Harmony 侧在 `Begin/Moving` 只更新本地预览，在 `End/Click` 写入最终十档值，保存期间短暂禁止冲突操作；
失败恢复数据库值并 toast。

这是对异步 UI 框架差异的安全适配，不改变最终持久语义。

## 被否决的方案

### 把 spacing/favorites 写回 selectedDefaultTemplate

否决。它会把共享线型状态与默认模板混为一体，并使编辑器再次污染新笔记默认值，违反 `rge/vge/rs0`
原版边界。

### 用 JS number 直接保存 packed paperSize

否决。八个值都超过 `Number.MAX_SAFE_INTEGER`，会发生不可逆精度损失，Letter/Legal 等值也可能被写错。

### Slider 每个 Moving 回调都立即写库并用单一 busy gate

否决。第一次异步写入后其余回调会被丢弃，UI 落点与数据库值可能分叉。

### 强制所有纸张颜色 opaque、所有读取 spacing 必须属于十档

否决。`tu1.b/fad.t/gq0` 证明原版实体保留 alpha、nullable spacing 和旧的正 Float；十档只属于当前 UI
写入选择，不是 Room 读取格式的完整合法域。

## 后果

正面：

- 设置页与编辑器现在真实共享收藏和分线型 spacing；
- 默认模板与当前笔记职责不再混淆；
- Room id、Float32、ARGB 和 64 位 packed size 均可无损往返；
- 事务、单写者和最终值提交避免竞态与半写入。

限制：

- 当前 UI 只提供收藏星标与 spacing；完整 paper color picker、legacy paper picker/组合仍待后续；
- 无设备运行态，popup 窄屏、拖动手感、收藏动画和跨重启体验需真机验证；
- Harmony 使用主 RDB 承载原版 SettingsDatabase 表，是平台适配而非数据库文件级一比一复制。

## 验证

- 专项：`D02_ORIGINAL_PAPER_SETTINGS_REPLAY_OK`
- 全量：`REPLAY_FILES=233 FAILED=0`
- `git diff --check` 通过
- `hvigorw clean --no-daemon` 成功
- clean 后 `note@ohosTest`、`note@default` 严格串行构建成功
- 未启动设备、模拟器、虚拟机、真机或 Hypium

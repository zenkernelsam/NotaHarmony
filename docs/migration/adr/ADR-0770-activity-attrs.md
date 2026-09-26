# ADR-0770 — activity 属性语义映射

## 状态

已接受。

## 背景

原版 6 个应用级 activity 属性在三版本零差异，其中 MainActivity 承载
关键窗口语义：全量 `configChanges`（自承载配置变化）、
`windowSoftInputMode=adjustNothing`（软键盘不 resize，自绘视口）、
`resizeableActivity`、`showWhenLocked`+`turnScreenOn`（录音/课堂
锁屏可达）。

## 决定

1. **configChanges → ArkUI 模型等价**：声明式 UI 天然不因配置变化
   重建 Ability，无需逐项声明。
2. **adjustNothing → 自绘视口保持**：Harmony 编辑器画布自管理 IME
   避让，不依赖系统 resize。
3. **resizeableActivity → 平台默认**：Harmony 分屏/自由窗默认支持，
   不单独声明。
4. **showWhenLocked/turnScreenOn 登记差异**：原版录音/直达场景的
   锁屏上显示属性在 Harmony 无等价设置；录音续存的锁屏可见性由
   连续任务系统横幅承担（平台范式差异，非缺陷）。
5. **keepScreenOn 已有编程等价**：`NotePage.keepScreenOnApplied`。
6. **widget ConfigActivity → 卡片配置页**：FolderNotesEditPage/
   NoteThumbnailEditPage 等价。
7. **sign-in activities fail-closed**：登录域整体不迁移。

## 后果

- activity 属性面闭合；`d02-activity-attrs.mjs` 回归覆盖
  三版稳定性与 Harmony 等价物。

## 已验证

- `d02-activity-attrs.mjs`：7/7。
- 全量 Desktop Replay + 双 HAP 构建（随 Phase 826 提交）。

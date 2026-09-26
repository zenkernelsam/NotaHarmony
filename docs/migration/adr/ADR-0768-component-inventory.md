# ADR-0768 — Manifest 应用组件明细闭合

## 状态

已接受。

## 背景

三版 manifest 逐项提取应用级 receiver/service/provider：

- receiver：6 个，三版本零差异（5 widget provider + AppUpgradeReceiver）。
- service：2→2→3（1.4.2 新增 `HwrEngineService` MyScript 引擎服务）。
- provider：1→2→3（1.0.3 新增 `ExportFileProvider` 替换旧 FileProvider；
  1.4.2 新增 `ApiGatedFirebaseInitProvider` 门禁初始化）。

## 决定

1. **widget provider → FormExtensionAbility 卡片族**：五个 widget provider
   全部映射 `noteformability`/`FormFeed` 数据源（呼应 Phase 804）；
   `LOCALE_CHANGED` 刷新由 Harmony 系统卡片重渲染承载。
2. **前台服务 → 连续任务**：RecordingForegroundService/AudioCaptureService
   由 `AUDIO_RECORDING` 长时任务等价（呼应 Phase 820）。
3. **provider → 文件共享机制**：WidgetImageProvider/ExportFileProvider 的
   content-URI 供给由 Harmony formBinding 像素注入与 fd-share 等价。
4. **HwrEngineService → 引擎适配层**：手写识别服务在 Harmony 端由
   `OriginalHandwritingRecognitionContextAdapter` 的引擎适配承担。
5. **AppUpgradeReceiver → 启动迁移**：`MY_PACKAGE_REPLACED` 重初始化由
   DB_VERSION 阶梯迁移器 + 启动链覆盖。
6. **ApiGatedFirebaseInitProvider fail-closed**：Firebase 门禁初始化
   无 Harmony 对应物（Firebase 全线 fail-closed）。

## 后果

- manifest 明细级闭合（Phase 800 计数层的明细展开）。
- 新增 `d02-component-inventory.mjs` 回归：三版组件数、新增条目、
  Harmony 等价物存在性。

## 已验证

- `d02-component-inventory.mjs`：7/7。
- 全量 Desktop Replay + clean/default、`note@ohosTest` HAP 构建（随 Phase 824 提交）。

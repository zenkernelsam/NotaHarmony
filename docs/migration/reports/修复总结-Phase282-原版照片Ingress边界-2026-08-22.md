# Phase 282 修复总结：原版照片 URI Ingress 边界

日期：2026-08-22（Asia/Shanghai）  
状态：已完成（静态边界与验证）；生产 picker caller 与产品 UI 明确延后。

## 目标

Phase 281 已提供大图规范化与持久化 primitive，但还没有原版对齐的照片入口。本阶段补齐 URI 列表到规范化
快照之间的可测试 ingress 边界，不把 UI 或系统 picker 冒充为已完成。

## 原版证据

直读 Desktop 只读反编译源：

- `bgj.java:185-330`：URI → cache temp file，硬上限 `104857600L`；MIME 空值 fallback `image/*` 后交给
  `vuh.b()`；成功返回文件 metadata，超限/失败删除临时文件。
- `tf9.java`：选中列表校验通过才保存整个 list；否则进入整体失败回调。
- `oj3.java`：png、jpg、jpeg、webp、tif、tiff、gif、heif、heic allowlist。
- `lb.java:345` case 8：picker 结果 list 进入上述 `tf9(..., 21)` 校验协程。
- 本地 SDK 确认 `PhotoViewPicker/PhotoSelectOptions/PhotoSelectResult.photoUris` 可用，但本阶段不启动 picker。

完整记录见 [ADR-0260](../adr/ADR-0260-original-photo-ingress.md) 与
[JADX evidence](../evidence/original-photo-ingress-jadx-2026-08-22.md)。

## 实现

新增 `note/src/main/ets/data/OriginalPhotoIngress.ets`：

1. `validateOriginalPhotoSelection()` 对有序 URI 列表执行 all-or-nothing allowlist 校验；
2. `importOriginalPhotos(uris, cacheDirectory)` 逐项保持输入顺序；
3. CoreFileKit reader 有界读取 URI，允许读取 `104857600 + 1` byte 以区分“恰好上限”和“截断/超限”；
4. 每项先写入 cache temp copy，再调用 Phase 281 `normalizeOriginalImageBytes()`；
5. 返回 bytes、生成文件名、最终 MIME 与 encoded/oriented dimensions；
6. 成功或失败都在 `finally` 中清理本次创建的全部临时文件；
7. URI reader 支持静态 fixture 注入，避免启动应用或 Hypium。

空选择、非字符串 URI、未支持扩展名、空文件、非安全整数长度或超过 100 MiB 都 fail closed。任何一项失败时
不返回部分成功集合。

## 验证

- ArkTS 静态检查：新模块只有项目既有可恢复异常提示；新 fixture 与 `List.test.ets` 无诊断。
- 新增专项 Replay：
  `docs/migration/replays/d02-original-photo-ingress.mjs`
  - 结果：`D02_ORIGINAL_PHOTO_INGRESS_OK TOTAL=10 FAILED=0`
- 全量 Replay：
  - `REPLAY_FILES=267 FAILED=0`
- clean 后严格串行双 HAP：
  - clean：`BUILD SUCCESSFUL in 2 s 418 ms`
  - `note@ohosTest`：`BUILD SUCCESSFUL in 9 s 538 ms`
  - `note@default`：`BUILD SUCCESSFUL in 1 min 3 s 919 ms`
  - unsigned HAP：`note-ohosTest-unsigned.hap` 6,490,159 bytes；`note-default-unsigned.hap`
    26,029,504 bytes
- `git diff --check` 通过；未启动模拟器、虚拟机、真机或 Hypium。

## 明确未闭环

- `PhotoViewPicker` 生产 caller、权限请求与用户可见错误提示未接线；
- toolbar / product UI 未增加；
- Pasteboard、相机、拖放与其他入口未处理；
- HEIC、HEIF、TIFF、GIF、EXIF 变体、WebP encoder 支持矩阵与真实设备内存/延迟未验收；
- Undo/Redo、重启、导入导出/同步与端到端体验继续开放；
- `T-042` 继续严格保留为整个 Goal 最后一项。

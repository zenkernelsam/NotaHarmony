# ADR-0799：实现原版 PDF+录音分享 ZIP 契约

## 状态

已接受（2026-09-23，Phase 855）

## 背景

原版分享面板的 `include_recording` 开关在 PDF 格式下触发
**容器升级**：`<title>.pdf` → `<title>.zip`（内嵌同名 PDF +
`Recordings/<name>.<ext>`）。Harmony 此前 UI 开关存在但
dispatch 将其丢弃——ZIP 产物路径从未实现（849 登记的暂缓
史诗）。

## 决定

**实现而非 fail-closed**：本地文件即可满足（录音 localPath +
页渲染 + ZipWriter），无后端依赖。

复现契约要点：

- `<safeTitle>.zip` = `<safeTitle>.pdf`（可选打开密码，
  密码作用于内嵌 PDF）+ `Recordings/<j0.m(name)>.<ext>`；
- 扩展名按 MimeTypeMap 语义 mime→ext（`audio/mp4`→`m4a`），
  未知回退 `"mp4"`（原版怪癖保留）；
- 重名追加 ` (N)`，N 自 1（字节码 iconst_1）；
- `fileH.exists()==false` 的录音条目跳过不阻断；
- 录音列表为空 → 裸 `.pdf`（原版早退路径）；
- `j0.m` 消毒规则等价实现（含 `\x00` 类字符与前导点剥离）。

落点：`PagePdfExporter.exportPdfZip`（单选）+
`LibraryPage.multiShare` PDF 分支（多选，逐笔记打包）；
`onSharePdf` 签名补 `includeRecording` 参数。

## 依据

- `decompiled_1.0.3/sources/defpackage/x59.java`、`yk9.java`、
  `j0.java`（消毒器）
- `decompiled_1.4.2/sources/defpackage/x8b.java`（同体重排）
- `note/src/main/ets/data/PagePdfExporter.ets`、`ZipArchive.ets`
- `note/src/main/ets/ui/editor/{EditorToolbar,NotePage}.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`

## 后果

- Replay `d02-share-zip-recordings.mjs`：23 项断言。
- 分享面契约补齐：`.note` 归档（assets/）+ PDF（可选加密）
  + PDF+录音 ZIP + 图片集 ZIP 四路径全部对位。
- 无新增依赖；ZIP 由既有 ZipWriter 承担（1GB 预算内）。

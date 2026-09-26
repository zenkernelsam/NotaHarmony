# Phase 812 — 同名资源内容差(中文报告)

## 本阶段结论

完成 res/ 树的**值/内容粒度**版本对比 —— 同名文件字节差与同键
string 值差，补完此前键名/文件名粒度无法覆盖的一层。

## 文件级(551 个共享路径，20 个内容变化)

- 9 个 `common_google_signin_btn_*`:GMS 登录按钮厂商矢量微调。
- `ic_launcher_monochrome.xml`:1.4.2 将单色图标内联 pathData
  重构为 `@string/ui_designsystem__app_mark_path` 共享引用 —
  徽标路径单源化(同一字符串可被图标与其他界面复用)。
- 10 个 values 文件:均为已登记面(strings/plurals/裁剪/RemoteConfig)。

## 键值级(1396 个共享 string 键，11 个值变化)

- 2 个 Crashlytics 构建元数据(非用户可见)。
- 9 个文案编辑：标题式大小写(`Copy Note ID`、`Show in Folder`)、
  来源标注(`From your files/photos`)、Giphy 署名(`Add GIF`→`Giphy`)、
  格式消歧(`Insert Math`→`Math (LaTeX)`)、句式(`Take a photo`)、
  计费错误详情("Google Play billing...")、主题文案精简("System")。

## Harmony 变更(文案对齐)

| 键 | 旧值 | 新值(对齐 1.4.2) |
|---|---|---|
| show_in_folder | Show in folder | Show in Folder |
| copy_note_id | Copy note ID | Copy Note ID |
| take_photo | Take Photo | Take a photo |
| insert_math | Math | Math (LaTeX);zh "公式 (LaTeX)" |

未对齐项登记：`add_files`/`insert_photo` 为紧凑菜单标签适配;
Giphy/计费文案为未实现/GMS fail-closed 面。

## 验证

- Replay:`d02-content-diff.mjs` 21/21;全量 685/685 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `note/src/main/resources/base/element/string.json`(4 键)
- `note/src/main/resources/zh_CN/element/string.json`(1 键)
- `docs/migration/evidence/phase-812-content-diff.md`
- `docs/migration/replays/d02-content-diff.mjs`
- `docs/migration/adr/ADR-0756-content-diff.md`
- 本报告

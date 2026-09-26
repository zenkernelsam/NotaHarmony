# ADR-0756 — 同名资源内容差登记与文案对齐

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0749(strings)、ADR-0753(plurals)、Phase 802(RemoteConfig)、
  Phase 789(GIF picker)

## 背景

此前的资源版本对比基于文件名/键名粒度。同名文件的字节级差异与
同键 string 的值差异是未登记的更深一层。

## 取证结论

- 551 个同名 res 文件中 20 个内容变化:9 个 GMS SignIn 按钮矢量
  (厂商微调)、1 个单色图标重构、10 个 values 文件(已登记)。
- 1396 个共享 string 键中 11 个值变化:2 个 Crashlytics 构建元数据
  + 9 个文案编辑(标题大小写、来源标注、Giphy 署名、格式消歧、
  句式精简、计费错误详情)。

## 决策

1. **文案对齐(已实施)**:Harmony 移植时沿用了 1.0.3 文案的键
   更新为 1.4.2 现值 —— `show_in_folder`/`copy_note_id`(标题式
   大小写)、`take_photo`(句式)、`insert_math` 含 zh_CN(LaTeX
   消歧)。
2. **紧凑标签登记**:Harmony 插入菜单的 `add_files`/`insert_photo`
   使用短标签("Files"/"Photo"),原版的来源标注式长文案
   ("From your files/photos")登记为布局适配，不强制对齐。
3. **fail-closed**:`add_gif`→"Giphy" 署名对应的 GIF 选择器面在
   Harmony 未实现(Phase 789);Google Play 计费错误文案为 GMS
   依赖。
4. **非语义项登记**:Crashlytics 构建指纹、单色图标的单源化重构
   (`@string/ui_designsystem__app_mark_path`)登记为打包层差异。

## 后果

- 资源层对比覆盖到值/内容粒度：键名、文件名、字节、值四层
  全部收敛。
- Replay `d02-content-diff.mjs` 21/21 钉住 11 个值差、图标重构
  与 Harmony 对齐结果。

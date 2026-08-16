# Phase 248 修复总结：原版共享纸张设置数据库、收藏与分线型 Spacing

## 本阶段目标

完成 Phase 247 明确留下的共享纸张设置缺口：严格依据原版 1.0.3 恢复 `PaperBackground`、
`BackgroundInfo`、四线型 fallback、十档 spacing 与 favorite/unfavorite，使 Settings 默认模板页和编辑器
纸张 popup 共享同一状态，同时保持二者各自的提交目标。

## 原版硬结论

- `SettingsDatabase_Impl/e47` 建有独立 `PaperBackground` 与 `BackgroundInfo`，不是 Preferences。
- `gq0/rs0` 为 PLAIN/LINES/GRID/DOTS 提供 `null/false` 与 `0.5f/true` 的空表 fallback。
- `rs0.f/ks0` 对 PLAIN no-op；其余线型按主键 upsert spacing，并保留 `hasOptions`。
- `kq0/kci/dhb` 使用十档 Float32 spacing 与十个离散 Slider 位置。
- `l3a.equals()` 不比较 Room id；`hge` 添加时按完整语义去重，删除时先找到已存对象再复用其 id。
- `ndj.f(h4a)` 把 metric width/height 的两个 Float32 raw bits 打包为 SQLite INTEGER。
- `tu1.b/fad.t` 保留完整 signed ARGB alpha；Room spacing 是 nullable Float，旧值也不必属于 UI 十档。
- `rge` 与 `vge` 共用 `rs0`，但默认模板和当前笔记的提交链仍然分离。

完整证据见 `docs/migration/evidence/original-paper-settings-database-jadx-dex-2026-08-16.md`。

## 已完成修复

1. 数据库升至 v63，新增原版两表、v62→v63 原子迁移，并加入最新 schema 创建列表。
2. 新增 `OriginalPaperSettings.ets`，覆盖四线型、十档 Float32、72 pt/in、完整 ARGB、八种 packed
   paperSize、nullable legacy spacing 和收藏语义 equality。
3. 新增 `OriginalPaperSettingsStore.ets`；所有写入走全局 `databaseWriteMutex` 与 SQLite transaction，
   严格检查 insert/update/delete 结果并在失败时 rollback。
4. packed paperSize 以十进制字符串绑定，让 SQLite INTEGER affinity 精确转换；读取使用
   `CAST(paperSize AS TEXT)`，不让 64 位值经过 JS number 回写。
5. `OriginalTemplatePickerState` 接受共享 BackgroundInfo：模板提交使用该线型 spacing，并可生成完整原版
   `l3a` 收藏候选；选择态也比较 spacing。
6. `PageSettingsPanel` 在设置页与编辑器两端加载同一 BackgroundInfo/favorites；模板卡加入收藏/取消收藏星标，
   非 Plain 且 `hasOptions=true` 时显示原版十档 spacing。
7. spacing 只更新共享表，不擅自写 `selectedDefaultTemplate` 或当前笔记；仍需再次点击模板卡才提交，保持
   `rge/vge` 边界。
8. 组件现在自行幂等初始化 DatabaseManager，默认模板页不再隐式依赖 Library/Editor 已先打开数据库。
9. 补齐中英文 loading、失败、收藏、取消收藏、模板设置和 spacing 文案与 accessibility text。

## 边修边审新增修复

### Slider 最终落点丢失

初版在每次 ArkUI Slider 回调中立即写库并设置全局 busy。拖动产生第一个异步写入后，其余 Moving/End
回调会被拒绝，可能只保存中途值。现改为 Begin/Moving 本地预览、End/Click 提交最终离散值；保存失败恢复
数据库值并提示。

### 过度收紧原版颜色与 spacing

初版把纸张颜色强制 opaque，并要求所有非 Plain spacing 必须非空且属于十档。继续直读 `tu1.b/fad.t/gq0`
后确认这会拒绝原版合法的 alpha、nullable spacing 和旧正 Float，甚至可能让导入笔记打开纸张面板时报错。
现只限制 UI 新写入为十档；模型和 Room 读取完整保留原版值。

### 默认模板页数据库初始化隐式依赖

`DefaultTemplatePage` 自身只读取 Preferences；若没有先经过 Library/Editor，初版共享 Store 会得到“数据库未
初始化”。现由复用组件在读取共享表前调用幂等 `DatabaseManager.initialize()`。

## Fixture、replay 与构建

- 新增 `OriginalPaperSettings.test.ets`，并更新 `OriginalTemplatePicker.test.ets`、
  `DatabaseHelper.test.ets`、`List.test.ets`。
- 新增 `d02-original-paper-settings.mjs`，覆盖：
  - v62→v63 原子迁移与失败回滚；
  - 四类空表 fallback、PLAIN no-op、spacing upsert/hasOptions；
  - 十档 Float32 与 nullable/legacy spacing；
  - 八种 packed size、SQLite INTEGER affinity；
  - 收藏去重、id 复用、取消收藏和事务回滚；
  - 设置页/编辑器共享、职责隔离、组件自初始化、Slider 最终提交；
  - 完整 ARGB alpha。
- 专项输出：
  `D02_ORIGINAL_PAPER_SETTINGS_REPLAY_OK ... slider-final-commit=1|self-db-init=1|nullable-legacy-spacing=1|argb-alpha=1`
- 全量桌面 replay：`REPLAY_FILES=233 FAILED=0`。
- `git diff --check` 通过。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 745 ms`。
- clean 后严格串行构建：
  - `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 817 ms`
  - `note@default`：`BUILD SUCCESSFUL in 31 s 549 ms`
- 只有项目既有 exception/deprecated 与未配置签名 warning；无编译错误。

## 未宣称完成与设备待测

- 未启动设备、模拟器、虚拟机、真机或 Hypium。
- 真机需验证：设置页/编辑器共享、跨重启、收藏星标点击不触发模板提交、十档拖动最终值、保存失败回退、
  popup 窄屏/横屏高度、`hasOptions=false` 隐藏设置、默认模板与当前笔记互不污染。
- 完整 paper color picker、legacy paper picker/颜色与收藏组合仍是下一阶段候选，不在本阶段冒充完成。

## 后续与长期文档约束

- 下一阶段优先继续原版 paper color/legacy picker，或按总纲选择更高风险静态缺口；继续边修边补审。
- T-042 APK 版本追踪严格放在整个 Goal 最后。届时必须单独写中文 Report，明确说明新建的追踪文档/工具、
  用途和操作流程，再把入口、阅读顺序与新版 APK decompile/diff 方法归纳进 Wiki、技术/API 文档和新手入门。

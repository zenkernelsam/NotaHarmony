# NotaHarmony — 持久 Goal 与硬性规则

> 本文件是按用户要求 hardcode 的长期规则，任何接手者/任何会话必须遵守。
> 最新交接文档：`NOTAHARMONY-GOAL-HANDOVER-SWE2-2026-09-21.txt`

## 长期 Goal（不要停止）

这个项目持续推进，不要停止。把对话当成 goal：按交接文档的 P0 → P1 → P3 → P2
顺序逐个 Phase 推进 Notability → HarmonyOS 移植，每 Phase 完成后按交接文档第四节
流程写中文 Report + ADR + evidence + Replay，更新两份修复总纲与总进展，精确
git add 后 commit，然后立刻进入下一个 Phase，直到用户明确叫停。

## 删除行为（hardcode）

**任何删除操作必须使用 Windows 回收站，禁止永久删除。**

- 禁止：`rm -rf`、`rm`（对非临时构建产物）、`Remove-Item -Recurse -Force`、
  `del /s`、格式化、直接 `fs.unlink` 等价物。
- 必须：用 PowerShell 的 VisualBasic FileIO 发送到回收站：

```powershell
powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('PATH\\TO\\DIR','OnlyErrorDialogs','SendToRecycleBin')"
powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('PATH\\TO\\FILE','OnlyErrorDialogs','SendToRecycleBin')"
```

- 唯一例外：`NotaHarmony-quarantine-2026-08-29\` 不得删除或覆盖（见下）；
  构建工具自行管理的产物（`note/build/`、`.hvigor/`、`oh_modules` 重装）由
  hvigorw clean / ohpm 自己处理，不算"删除用户文件"。
- 归档优先于删除：凡属交接文档 P0 清单的目录，先确认已归档/无引用，再送回收站。

## 硬约束（摘自交接文档第五节，逐条有效）

- 正式 Git 工程仅此目录；`C:\Users\Cisco He\Desktop\Notability` 只读原版
  资料（APK/decompiled/JADX/证据），不得在那里创建鸿蒙源码工作树。
- 不得启动模拟器、虚拟机、真机或 Hypium（除非用户明确要求）。
- T-042（原版 APK 版本追踪）严格保留为整个 Goal 最后一项。
- 不 push，除非用户明确要求。
- 禁止 `git reset --hard` / `git checkout -- <broad path>` / `git add .`；
  只精确 `git add <file>`。
- `NotaHarmony-quarantine-2026-08-29\` 已通过 `.git/info/exclude` 排除，
  不得删除或覆盖其内容。
- `Chat History/` 与 `note/oh-package-lock.json5` 是未跟踪保护项，不得进 index。
- Hvigor 构建：`HVIGOR_USER_HOME=C:\Users\Cisco He\.hvigor`（不含空格），
  所有 `hvigorw.bat` 调用必须加 `--no-daemon`；
  `NODE_HOME=C:\Program Files\Huawei\DevEco Studio\tools\node`。
- 全量 Desktop Replay 基线：424/424 全绿（`docs/migration/replays/` 入口脚本，
  用 node 执行）。

## 每 Phase 验收标准（交接文档第一节）

1. 原版行为有硬证据（decompiled_1.0.3 类文件或 SHA-256 校验提取物）。
2. Harmony 实现与原版对齐；不能等价时写 fail-closed ADR。
3. 新增/更新 fixture/Replay，全量 Desktop Replay 全绿。
4. ArkTS 静态检查无新增错误。
5. clean + note@ohosTest + note@default 两个 HAP 静态构建成功。
6. 写中文 Report（`docs/migration/reports/`）。
7. 更新 `修复总纲.md`、`修复总纲2.md`、`修复进展-2026-08-09.md`。

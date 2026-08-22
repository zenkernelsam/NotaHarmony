# NotaHarmony Goal 交接文档（Phase 280 后）

> 交接日期：2026-08-22（Asia/Shanghai）
> Goal 状态：未完成，下一任务继续 active
> 完整 Goal 中心估计：约 **80%**
> 唯一正式工程：`C:\HarmonyProject\NotaHarmony`
> 原版参考根目录：`C:\Users\Cisco He\Desktop\Notability`
> 原版 1.0.3：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 一、可直接使用的启动 Prompt

新任务应以 `C:\HarmonyProject\NotaHarmony` 为项目/工作区；若界面仍从 Desktop 打开，也必须先切到正式仓，
不得在 Desktop 创建或继续维护 Harmony 源码工作树。发送：

```text
/goal 请先完整阅读：
C:\HarmonyProject\NotaHarmony\docs\migration\handover\NOTAHARMONY-GOAL-HANDOVER-Phase280-2026-08-22.md

正式 Git 与唯一允许修改的鸿蒙工程是：
C:\HarmonyProject\NotaHarmony

C:\Users\Cisco He\Desktop\Notability 只用于读取原版 APK、decompiled_1.0.3、JADX/DEX、调用图和既有临时逆向证据；不得在那里新建或继续维护任何 NotaHarmony 鸿蒙源码工作树。

请先检查 cwd、workspace root、Git HEAD/status/remote 和正式仓写权限；确认 Phase 280 实现提交 0582fde5e10ae2cb5d463e299f0487d0cb71ce32 位于当前 HEAD，且 c1be5f0 仍是祖先。origin/main 交接时仍为 f71961b6ee8555bdd2d6be3b64d0b64efa2e9540，本交接没有 push。

随后继续原 Goal：严格参考原版 App 的实现方式，同时修复原版移植中暴露的逻辑错误与 Harmony 适配问题，追求接近原版功能和原生体验。先读两份修复总纲、总进展、Phase 280 Report/ADR/evidence/replay；对候选项现场重放，避免重复修已闭环内容。边修边补审，每阶段写中文 Report、证据、Replay/fixture，并更新两份修复总纲与总进展。

优先评估 Phase 280 明确开放的原版大图规范化链：超过 3000px 时缩放、应用 EXIF rotation、WebP lossy 85 重编码及 MIME/长度更新。必须先核对 DevEco SDK 的 ImageKit API 和原版 vuh/w34 硬证据；平台不能等价时做显式、可测试的 Harmony adapter/fail-closed，不伪装原版能力。之后才考虑 URI/FD/Pasteboard/相册 caller 与产品入口。

不得启动模拟器、虚拟机、真机或 Hypium，除非用户以后明确要求。允许静态分析、Desktop Replay、ArkTS fixture 编译、clean 和两套 HAP 打包。不得清理 handover 中列出的临时产物；T-042 APK 版本追踪必须严格保留为整个 Goal 最后一项。
```

## 二、不可违反的工作区与执行纪律

1. HarmonyOS 源码、测试、ADR、Replay、迁移证据、Report、总纲和 handover 只在
   `C:\HarmonyProject\NotaHarmony` 修改和提交。
2. Desktop `Notability` 仅用于读取原版和既有逆向产物。`.codex-worktree-notaharmony-phase264` 是历史临时
   worktree，不得恢复为活动开发仓，也不得产生新 Harmony 提交。
3. 不得擅自删除、移动或暂存陌生/保护文件。只能精确 `git add` 本阶段文件，禁止 `git add .`。
4. 原版硬证据与 Harmony 平台适配必须分开写。缺等价 API 时应记录差距并 fail closed，不能发明常量或行为。
5. 147 条是最初审计基线，不是当前剩余数。后续继续“现场重放 → 确认真缺口 → 修复 → fixture/Replay →
   双 HAP → 中文 Report”，不要为追求抽象的“审全”停止修复。
6. 当前明确禁止启动模拟器、虚拟机、真机或 Hypium。静态 HAP 成功不得冒充运行态或端到端验收。
7. 每个 Phase 都要更新：
   `docs/migration/audit-2026-08/修复总纲.md`、
   `docs/migration/audit-2026-08/修复总纲2.md`、
   `docs/migration/reports/修复进展-2026-08-09.md`。
8. `T-042` 必须是整个 Goal 最后一项。完成时另写中文 Report，并把 APK 版本追踪工具/文档的用途、入口、
   阅读顺序和新版 APK decompile/diff 流程归入 Wiki、技术/API 文档和新手入门。

## 三、正式 Git 真相

Phase 280 代码提交：

```text
0582fde5e10ae2cb5d463e299f0487d0cb71ce32
fix(image): persist original local insertion atomically
```

- Phase 280 提交包含 16 个文件，`1864 insertions / 9 deletions`。
- `origin/main` 在交接时仍为 `f71961b6ee8555bdd2d6be3b64d0b64efa2e9540`；没有 push。
- 本 handover 会作为 Phase 280 之上的 docs-only 提交保存，所以接手时当前 HEAD 应是 handover 提交，
  `git rev-parse HEAD^` 应为 `0582fde5e10ae2cb5d463e299f0487d0cb71ce32`。
- remote：`https://github.com/zenkernelsam/NotaHarmony.git`。
- `c1be5f0` 已现场确认是当前 HEAD 祖先；Phase 264～266 完整保留。
- 提交 Phase 280 前保护项进入 index 的数量为 `0`。

Phase 267～280 的主线提交：

| Phase | 提交 | 主题 |
|---|---|---|
| 267 | `3371e5a` | CFBinaryPlist canonical structure |
| 268 | `2e8e796` | editor committed persistence state |
| 269 | `e68b231` | original Ink width interpolation |
| 270 | `91ea3e6` | SET_METADATA six registers |
| 271 | `6f52011` | explicit-null title register/history |
| 272 | `689f0b4` | local SET_METADATA outbound |
| 273 | `3c5d3c3` | durable metadata register history |
| 274 | `c9f692a` | handwriting language/provider boundary |
| 275 | `f852812` + `52c9d14` | selected Ink → OCR pointer adapter/report |
| 276 | `f8b5bab` | Convert-to-Text plan/freshness boundary |
| 277 | `9054d1a` | atomic conversion persistence/history |
| 278 | `47b2562` | global preference/Locale/capability adapter |
| 279 | `f71961b` | production conversion coordinator/result gate |
| 280 | `0582fde` | original local IMAGE atomic persistence |

`4cac2ca` 是这段历史中的模拟器操作指南/ABI 文档提交，不属于 Phase 267 修复，不得误删或改写历史。

## 四、Phase 280 已完成内容

### 4.1 原版硬证据

直读原版 1.0.3 `bvh/bgj/vuh/w34` 与 `yr` debug extraction，确认：

- 显示尺寸同时受页面宽高各 80% 与 `320 / zoom` 限制；先以 anchor 为中心，再逐轴 clamp。
- IMAGE CREATE_BLOCK 保留 intrinsic width/height，显示 fit 通过 transform `scaleX/scaleY` 表达。
- URI 入口保持 item 顺序，最多复制 100 MiB；MIME 缺失回退 `image/*`。
- 图片必须可解码；EXIF 90/270 度交换对外宽高。
- 任一轴超过 3000px 时，原版会实际缩放、应用 EXIF rotation，并以 WebP lossy 85 重写。

证据哈希：

| 文件 | SHA-256 |
|---|---|
| `bvh.java` | `432FB846325FF4B53089E983B3FE6610AEE9267F275D9412581A7BD453A42025` |
| `bgj.java` | `511F49014AFCD5782CAB0538752C4E9DA611D95F67020532786EDAF176DA6A12` |
| `vuh.java` | `00D902C109245A8B702272AB17173581068FD064B5B1797B47E01222E47D497D` |
| `w34.java` | `8CD08C868F2081EDDB23DEF19DE5060CF7F7495FA0E434D6CCEFCB5E39433068` |
| `.codex-tmp-phase280-yr-debug.java` | `CCE970FB9F6FD7A93AA9A72CBA62A865852746C3DA7F8BF407C7BB6883AE4B5B` |

### 4.2 Harmony 实现

已闭环的底层路径：

```text
immutable normalized bytes
→ ImageKit header/MIME/EXIF/PixelMap decode gate
→ SHA-512 canonical AssetHash + 8 little-endian uint64 words
→ assets/pending full write + fsync + atomic rename
→ IMAGE CREATE_BLOCK reducer + uploadable operation
→ note_asset LOCAL/UPLOADED/DOWNLOADED merge
→ one page revision + snapshot/order/search
→ PageMutation durable history
→ one SQLite commit
→ post-commit availability publish
```

关键实现：

- `note/src/main/ets/core/model/OriginalImageInsertPlan.ets`
- `note/src/main/ets/data/AssetDigest.ets`
- `note/src/main/ets/data/ImageAssetPackageStore.ets`
- `note/src/main/ets/data/StrokePersistence.ets`

核心不变量：

- 输入字节在异步边界前复制；`sha512Digest()` 返回独立 64-byte 副本。
- ImageSource 与 PixelMap 分别在 `finally` release；header 或完整 decode 任一步失败都拒绝。
- 3000px 规范化尺寸在模型层和 persistence 层双重 fail-closed。
- 锁序固定为 `assetMutationMutex → editorPersistenceMutex/databaseWriteMutex → SQLite transaction`。
- final 已存在时必须 size 与内容逐字节完全相同；事务失败只删除本调用创建的 final，不删复用文件。
- reducer 前 reconcile canonical/legacy 历史资产。私有旧路径同内容或缺失可改指 canonical final，但旧文件保留；
  私有冲突或应用目录外可读路径拒绝且不删除。
- CREATE_BLOCK、uploadable operation、资产合并、revision/snapshot/search/history 在同一 transaction；
  availability 只能在 commit 返回后发布。

### 4.3 测试与文档

- `note/src/test/OriginalImageInsertPlan.test.ets`
- `note/src/test/StrokePersistence.test.ets`
- `note/src/test/AssetArrival.test.ets`
- `note/src/test/List.test.ets`
- `docs/migration/replays/d02-original-image-insert-persistence.mjs`
- `docs/migration/replays/d02-image-asset-reference-integrity.mjs`（更新旧静态定位）
- `docs/migration/adr/ADR-0258-original-image-insert-persistence.md`
- `docs/migration/evidence/original-image-insert-persistence-jadx-2026-08-22.md`
- `docs/migration/reports/修复总结-Phase280-原版图片插入原子持久化-2026-08-22.md`

## 五、Phase 280 最终验证

| 门禁 | 结果 |
|---|---|
| Phase 280 专项 Replay | `D02_ORIGINAL_IMAGE_INSERT_PERSISTENCE_OK TOTAL=25 FAILED=0` |
| 相邻 asset/IMAGE Replay | `RELATED_REPLAY_FILES=4 PASSED=4 FAILED=0` |
| 全量 Desktop Replay | `REPLAY_FILES=265 PASSED=265 FAILED=0` |
| `git diff --check` | 通过，仅 CRLF 提示 |
| clean | `BUILD SUCCESSFUL in 6 s 868 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 13 s 350 ms` |
| 同一次 clean 后 `note@default` | `BUILD SUCCESSFUL in 1 min 8 s 355 ms` |

unsigned HAP：

- `note-ohosTest-unsigned.hap`：6,490,159 bytes；
- `note-default-unsigned.hap`：26,011,956 bytes。

只执行了静态 ArkTS/native 编译和 HAP 打包；没有运行 Hypium 或任何设备。warning 为项目既有异常处理、
弃用 API 与 unsigned signing 提示，没有 Phase 280 编译错误。

## 六、明确未完成与下一阶段建议

Phase 280 **不等于任意图片已可直接插入**。仍开放：

1. 超过 3000px 的真实 resize、EXIF rotation 应用、WebP lossy 85 编码及 MIME/长度更新。
2. URI/FD/Pasteboard/系统相册 caller、权限、缓存临时文件清理和产品 UI 入口。
3. 小尺寸 EXIF 图片经 `ImageAssetLoader`/renderer 的方向行为；当前没有显式 EXIF transform，需设备证据。
4. 真实设备 decode、文件系统 crash、Undo/Redo、保存重启、导入导出/同步与视觉体验。

推荐下一 Phase 先现场评估“大图规范化 adapter”，因为这是 Phase 280 底层 API 的直接前置缺口：

- 重读 `vuh.java:44-137`、`w34` orientation mapping 与 Phase 280 evidence。
- 查 DevEco SDK 声明/离线文档，确认 ImageKit 的 decode desired size、PixelMap rotation、WebP lossy quality、
  输出字节与资源释放契约；不要凭 Android API 名字类推。
- 规范化必须作为一个整体更新 bytes、oriented dimensions、MIME 和 fileSize；不得只改 metadata。
- 继续保持 100 MiB 输入预算、3000px 输出边界、失败清理和 immutable byte ownership。
- 如果 API 21 不能等价输出 WebP lossy 85，写明确 ADR 与可测试 fail-closed，不要假装完成原版行为。
- adapter 静态闭环后，再独立处理 URI/FD/Pasteboard/相册 caller，最后才接 UI。

若现场证明该 adapter 当前无法由静态证据安全实现，应回到两份总纲重放其他高风险静态项；不要为了 Phase 编号
机械选题，也不要用 HAP 打包成功冒充运行态关闭。

## 七、Goal 进度估计

给用户的单一百分比中心值是 **80%**。

- 纯代码、数据契约和静态架构大约在 90%～93%。
- 完整 Goal 还必须计入图片入口等剩余产品链、设备/像素/交互/性能验收、验收暴露后的返修、最终 Wiki/API/
  新手文档和最后的 T-042，因此完整完成度按约 80% 更诚实。
- 这不是可机械计数的燃尽值；设备尚未启动，最后约 20% 的不确定性明显高于普通静态修复阶段。

## 八、保护项与当前工作树

Phase 280 提交后，正式仓只有以下既有未跟踪保护项；它们未进入 index，不得擅自删除或提交：

```text
C:\HarmonyProject\NotaHarmony\.codex-tmp-androidlatex\
C:\HarmonyProject\NotaHarmony\.codex-tmp-microtex\
C:\HarmonyProject\NotaHarmony\.codex-tmp-tinyxml2\
C:\HarmonyProject\NotaHarmony\.hvigor-user-phase270\
C:\HarmonyProject\NotaHarmony\.hvigor-user-phase271\
C:\HarmonyProject\NotaHarmony\.hvigor-user-phase272\
C:\HarmonyProject\NotaHarmony\Chat History\
C:\HarmonyProject\NotaHarmony\note\oh-package-lock.json5
```

`.hvigor-user-phase271` 是本轮已验证构建用户目录，可复用，但仍不得提交。

## 九、临时产物完整账单

用户明确要求记录并保留；**不要自行清理**。

### 9.1 C 盘/HarmonyProject 缓存

| 路径 | 现场状态 |
|---|---|
| `C:\codex-hvigor-phase279` | 存在；693 files；15,052,830 bytes |
| `C:\hvigor-user-phase277` | 存在；692 files；15,052,185 bytes |
| `C:\codex-node-phase277` | 存在；7,718 files；410,343,789 bytes |
| `C:\hvigor-user-phase270` | 存在；1 file；34 bytes |
| `C:\ohos-hvigor-cache` | 存在；36 files；20,405,663 bytes |
| `C:\HarmonyProject\.hvigor-phase267` | 存在；1 file；34 bytes |
| `C:\HarmonyProject\NotaHarmony\.hvigor-user-phase270` | 存在；1 file；34 bytes |
| `C:\HarmonyProject\NotaHarmony\.hvigor-user-phase271` | 存在；702 files；15,155,121 bytes |
| `C:\HarmonyProject\NotaHarmony\.hvigor-user-phase272` | 存在；1 file；34 bytes |

### 9.2 Desktop 根目录的 21 个 `.codex-*` 项

| 路径 | 类型/大小 |
|---|---|
| `.codex-tmp-phase249-jadx` | dir；2 files；59,250 bytes |
| `.codex-tmp-phase266-callgraph` | dir；1 file；16,391,969 bytes |
| `.codex-tmp-phase266-f0f.java` | file；129,805 bytes |
| `.codex-tmp-phase266-jadx-config` | empty dir |
| `.codex-tmp-phase266-k2f.java` | file；18,599 bytes |
| `.codex-tmp-phase266-lb9.java` | file；40,817 bytes |
| `.codex-tmp-phase266-lib.java` | file；22,303 bytes |
| `.codex-tmp-phase266-w95-fallback.java` | file；8,690 bytes |
| `.codex-tmp-phase266-w95-simple.java` | file；5,812 bytes |
| `.codex-tmp-phase273-vnf-simple.java` | file；46,915 bytes |
| `.codex-tmp-phase274-dex` | dir；1 file；7,469,228 bytes |
| `.codex-tmp-phase280-ad9-debug.java` | file；13,390 bytes |
| `.codex-tmp-phase280-bgj-debug.java` | file；15,632 bytes |
| `.codex-tmp-phase280-frf.java` | file；814 bytes |
| `.codex-tmp-phase280-jadx-yr` | empty dir |
| `.codex-tmp-phase280-je4.java` | file；1,185 bytes |
| `.codex-tmp-phase280-ns-debug.java` | file；86,680 bytes |
| `.codex-tmp-phase280-yr-debug.java` | file；59,392 bytes |
| `.codex-tmp-phase280-yr.java` | file；9,683 bytes |
| `.codex-tmp-phase280-zc9.java` | file；6,073 bytes |
| `.codex-worktree-notaharmony-phase264` | dir；4,194 files；336,041,353 bytes |

以上路径的共同根目录是 `C:\Users\Cisco He\Desktop\Notability`。用户所写
`C:\Users\Cisco He\Desktop\Notability\.codex-tmp-\*.java` 的实际根级 Java 项已经逐项列出。

### 9.3 本轮已删除的纯临时 diff

正式仓曾有以下 4 个未跟踪 review/diff 快照，本轮按 Phase 280 收尾要求删除：

```text
.codex-phase280-diff.txt                 33,735 bytes
.codex-review-image-store.diff           28,594 bytes
.codex-review-rest.diff                  18,958 bytes
.codex-review-stroke.diff                33,266 bytes
```

它们从未进入 Git，因此不能通过 Git 恢复；但只是当前工作树的临时差异副本，没有独有源码或逆向证据。
全部有效内容已进入 `0582fde`，Desktop 逆向产物仍完整保留。

## 十、接手后的第一组命令

```powershell
Set-Location -LiteralPath 'C:\HarmonyProject\NotaHarmony'
Get-Location
git status --short --branch
git rev-parse --show-toplevel
git rev-parse HEAD
git rev-parse HEAD^
git rev-parse refs/remotes/origin/main
git merge-base --is-ancestor c1be5f0 HEAD
git merge-base --is-ancestor 0582fde5e10ae2cb5d463e299f0487d0cb71ce32 HEAD
git log --oneline --decorate -8
git remote -v
```

期望：

- toplevel 为 `C:/HarmonyProject/NotaHarmony`；
- `0582fde...` 是当前 HEAD 的祖先，且通常是 handover docs commit 的直接父提交；
- `origin/main` 仍为 `f71961b...`，除非用户/其他任务已明确 push；
- status 只有第八节保护项，不应有未说明的 tracked 修改。

然后读：

```powershell
Get-Content -Raw 'docs\migration\reports\修复总结-Phase280-原版图片插入原子持久化-2026-08-22.md'
Get-Content -Raw 'docs\migration\adr\ADR-0258-original-image-insert-persistence.md'
Get-Content -Raw 'docs\migration\evidence\original-image-insert-persistence-jadx-2026-08-22.md'
node 'docs\migration\replays\d02-original-image-insert-persistence.mjs'
git diff --check
```

专项期望：`D02_ORIGINAL_IMAGE_INSERT_PERSISTENCE_OK TOTAL=25 FAILED=0`。

## 十一、交接结论

- Phase 280 已完整提交，验证为专项 25/25、相邻 4/4、全量 265/265，clean 与两套 HAP 均成功。
- 代码提交未 push；handover 作为其上的 docs-only 提交保存在正式仓。
- Desktop 21 个 `.codex-*` 项和用户列明的 C 盘/Hvigor/Node 缓存均保留；只删除了 4 个无独有内容的临时 diff。
- 下一阶段最自然的候选是原版大图规范化 adapter，但必须先用 SDK 与原版证据现场证明可实现。
- Goal 继续 active，完整完成度中心估计约 80%；设备验收、最终文档和最后的 `T-042` 仍未完成。

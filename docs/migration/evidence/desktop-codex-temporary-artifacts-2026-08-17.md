# Desktop Codex 临时逆向成果盘点（2026-08-17）

## 盘点范围

- 根目录：`C:\Users\Cisco He\Desktop\Notability`
- 盘点规则：根目录下所有 `.codex-*` 项目；不把活动工作树内部生成物再次当作独立临时成果。
- 结果：10 个根级项目，其中 1 个活动工作树、3 个临时目录、6 个临时 Java 文件。
- 保留原则：在有价值结论进入 evidence/Replay/Report、工作树提交并迁回正式主仓之前，不删除任何项目。

## 文件清单与哈希

| 路径 | 大小 | SHA-256 | 归类 |
|---|---:|---|---|
| `.codex-tmp-phase249-jadx/p4a-simple.java` | 57,402 | `C3CD035405049AC1A414267276248D9FF77F748E1928AF4AD2C21C488556AEF8` | Phase 249 可读 JADX 补充输出，已被纸色/纹理 evidence 引用 |
| `.codex-tmp-phase249-jadx/vge-simple.java` | 1,848 | `D3E0A9A36F3C4B52CA17CEF2948C2C0650DD3B0EAA17768420F5B8764F08D7A1` | Phase 247/249 picker 路由交叉核对；正式 source 已有等价可读版本，原文件仍保留 |
| `.codex-tmp-phase266-callgraph/callgraph.json` | 16,391,969 | `F37C1258DAC026AA95CC52F98AD4C88AC325D9B35338603E64122A584A49B53C` | 88,893 节点、238,339 边的 APK 调用图 |
| `.codex-tmp-phase266-f0f.java` | 129,805 | `E79D146539C0D31E73C3CC941633397E1F452AAE544BD135AE8E71F6A7DDBB46` | 编辑器 Compose/JADX 探索输出，持有 `k2f` UI 接线，但没有新增独立 hold 常量 |
| `.codex-tmp-phase266-k2f.java` | 18,599 | `A624354534F219D7920D3A79601A73F4A0555C14888EAFEBE7C6F2F75B8B7B5F` | 关键可读输出；恢复 recognizer winner 到 `aih.b()` 最终 ShapeDefinition 的发布链 |
| `.codex-tmp-phase266-lb9.java` | 40,817 | `421B378C0CAE44015B8E84BC95EC2207949E35FC6CEA686E4ED296A20FEC0011` | 追踪 coroutine 合并类时产生；未发现独立 shape-hold 语义，保留供后续交叉核对 |
| `.codex-tmp-phase266-lib.java` | 22,303 | `AB63574A1315CAB36240B9566C6F99FE2EC14D25A4C4FEB9C3AB475936E3A8DC` | 追踪 coroutine 合并类时产生；未发现独立 shape-hold 语义，保留供后续交叉核对 |
| `.codex-tmp-phase266-w95-fallback.java` | 8,690 | `1C019DF1838C1025B9A2B2DC0E527658198181D10F70EACC27153C3945D27714` | `w95` 失败块的 fallback JADX 输出 |
| `.codex-tmp-phase266-w95-simple.java` | 5,812 | `999FDCA55A0852AA14348A3CDFB72EC52FD07ECB179F3E39607A14DCDFB1A1FB` | `w95` 简化可读输出，恢复 MotionEvent → `tc5/z95` 的生命周期接线 |
| `.codex-tmp-phase266-jadx-config/` | 0 个文件 | 不适用 | 本轮 JADX 配置临时目录；为空但仍保留，不假设可安全删除 |

活动工作树为 `.codex-worktree-notaharmony-phase264/`。盘点时 HEAD 为 `4718f12`，相对 `origin/main`
ahead 2，Phase 266 代码和文档尚未提交。该目录是当前唯一可写的 NotaHarmony 工作区，不是缓存。

## 已固化的临时成果

### Phase 249

`p4a-simple.java:362-370` 的资源查找与缓存结论已经进入
`original-paper-color-legacy-texture-jadx-resource-2026-08-16.md`，对应 Replay 也读取正式原版 `p4a`。
`vge-simple.java` 与正式 `decompiled_1.0.3/sources/defpackage/vge.java` 的 picker 职责一致，没有只存在于
临时文件而尚未登记的业务规则。

### Phase 266

- 调用图确认 `k2f.k(...) -> aih.b(g5d,h8d)` 是 resolved edge；`aih.b()` 再调用 `tsi.a`、`vaj.a`、
  `n4j.b`，分别构造 LINE、POLYGON、NORMAL_SHAPE 最终定义。
- `.codex-tmp-phase266-k2f.java:426-480` 恢复了 recognizer 八类 ordinal 的接收、`aih.c/e/b/d` 转换和
  `ge3` 发布；这排除了“内部八类必须各自新增持久 ElementType”的错误方向。
- `.codex-tmp-phase266-w95-simple.java:59-199` 恢复 MotionEvent 流持续调用 `tc5.a()`，并仅在
  `pauseDetectionLatestPoint != null && job == null` 时通过 `z95.c()` 启动 500ms job；Up/Cancel 路径调用
  `tc5.b()` 清理。
- `w95-fallback.java` 与 `w95-simple.java` 是同一 classes2.dex 方法的两种反编译结果。证据文档只采用两者
  共同支持、且能由 `tc5/z95/y95` 正式 source 再验证的结论。
- `f0f/lb9/lib` 已全文检索 shape 相关符号；除 `f0f` 的 `k2f` UI 接线外，没有发现比正式 source 或上述
  `k2f/w95` 输出更强的独立规则，因此没有把探索噪声写成产品契约。

## 保留与迁移约束

1. Phase 266 提交前不得删除上述文件、空目录或活动工作树。
2. 迁回 `C:\HarmonyProject\NotaHarmony` 时先核对提交 ID、文档中的 SHA-256 与正式主仓状态，再讨论清理。
3. 16 MB 调用图不直接复制进 Git；其不可替代的节点数、边数、resolved 路径和原文件哈希已写入本清单与
   Phase 266 evidence，原始 JSON 继续保留在 Desktop。
4. 活动工作树必须在正式主仓包含 Phase 264～266 提交且经 `git log/status` 复核后才可退役；本阶段不执行退役。

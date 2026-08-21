# 原版 Convert-to-Text 编排与结果门禁证据（Phase 279）

## 1. 证据范围

本阶段只读取 `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3` 的原版 1.0.3
反编译源码；Harmony 实现、fixture、Replay、ADR 和本 evidence 均只写入正式仓
`C:\HarmonyProject\NotaHarmony`。没有启动模拟器、虚拟机、真机或 Hypium。

原版来源目录：

```text
C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage
```

## 2. 原版调用链与哈希

| 文件 | SHA-256 |
|---|---|
| `dhb.java` | `F5E669CC818293476C8B0516C30875ADD8FFED96276C71C449C011235C45F7B3` |
| `hc5.java` | `9F524AADE41D95ECF36DBE24B69E4A19587932B3DF8FA134A8EE4E37A3C56E5C` |
| `tsc.java` | `D541B9764E885C23011F1CC757195CB84C83DF6A4BC1444FB281FC8B9CD7E23B` |
| `bt1.java` | `A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA` |
| `lvd.java` | `98B61EF1C9989BE253FD2E452294E539AEA32F3166F0A9E9DE1C04725D4C69F7` |
| `cq.java` | `57973CA56CF0F04BF02BC869BB0B54160E60F66FB1D5933984BB23E2AD956C4B` |
| `re0.java` | `3F784533135046413584598574F701F34A5D0B8963E5B9957D10919A1190ECD7` |

关键静态事实：

1. `dhb.java:17818-17833` 逐项从当前单页集合取出 `s06`，以 `wqh.e()` 过滤后建立
   `arrayList7`；`arrayList8` 保存这些 eligible 实体的 ID 快照。`xsc.v(arrayList7, ...)`
   只对该快照计算单页/union bounds。
2. `hc5.java:85-94` 再次以 `jc5.a(..., true)` 获得识别列表；空列表直接返回空字符串，非空才
   调用异步 `pm8.c(map, list, dc5, continuation)`。
3. `bt1.java:57-62` 在一个 `xq9` transaction callback 内严格执行：

   ```text
   u5j.l  DELETE_ENTITIES
   u5j.f  CREATE_BLOCK(TEXT)
   s5j.i  INSERT_STRING
   ```

4. `tsc.java` 收到字符串后调用 `lvd.E0(str)`；`lvd.E0` 对每个 UTF-16 code unit 调用
   `cq.f0`，而 `cq.f0` 为 `Character.isWhitespace(c) || Character.isSpaceChar(c)`。因此全空白结果
   进入失败/不提交分支；非空结果不应被 `trim()`，原版写回保留前后空白。
5. `re0.java:731-733` 仅在异步转换完成后记录 `Convert Handwriting`，不是 provider 请求发出时记录。

## 3. Phase 279 的 Harmony 对齐

### 3.1 共享结果门禁

`OriginalHandwritingConversionTextPolicy.ets` 将以下规则集中到一个纯函数：

- 空字符串拒绝；
- 原版全空白字符串拒绝；
- `TextEncoder` UTF-8 编码必须能由 `TextDecoder` 严格往返；
- 实际 payload 字节数不得超过 1 MiB；
- 合法文本原样保留，不做 trim。

判定顺序也按调用链分层：`tsc/lvd` 的全空白语义先于后续 `INSERT_STRING` serialization 门禁；因此
超过 1 MiB 的纯空白字符串仍归类为全空白，而不是 Harmony wire 超限。

`OriginalInsertTextPayloadEncoder.ets`、planner 和 `StrokePersistence` 都调用同一门禁，避免
planner 用 UTF-16 `string.length` 放行、直到 transaction 才因 UTF-8 超限或孤立 surrogate 失败。

覆盖的边界：

| 输入 | 结果 |
|---|---|
| 恰好 `1,048,576` 个 ASCII 字节 | 接受 |
| `1,048,577` 个 ASCII 字节 | 拒绝 |
| UTF-16 长度看似较短、UTF-8 超过 1 MiB 的多字节文本 | 拒绝 |
| 孤立 surrogate | 拒绝 |
| 仅空格/不换行空格/全角空格/换行 | 拒绝 |
| `  hello  ` 或 `  你好  ` | 接受并原样保存 |

### 3.2 Coordinator 边界

`OriginalHandwritingConversionCoordinator.ets` 是可注入、可 fixture 的生产编排边界：

```text
immutable page snapshot
  → adaptOriginalHandwritingSelection
  → planOriginalHandwritingConversion
  → context reader
  → async stroke-native provider
  → freshness reader (page/generation/fingerprint)
  → commitOriginalHandwritingConversion
```

它结构化区分：

- `INVALID_REQUEST` / `PLAN_REJECTED`；
- `PROVIDER_UNAVAILABLE`、`CONTEXT_FAILURE`、`PROVIDER_FAILURE`、`PROVIDER_NO_RESULT`；
- `RESULT_REJECTED`、`STALE_RESULT`、`FRESHNESS_FAILURE`；
- `PERSISTENCE_FAILURE`；
- `SUCCESS`。

编排层的安全约束：

1. planner、OCR 与 persistence 使用同一 `acceptedStrokeIds` 序列。
2. OCR 前通过 persisted-element codec 深拷贝 exact `StrokeElementData`；调用方后续修改原对象不影响
   提交快照。
3. type-25 persistence 只接受 canonical original operation identity；coordinator 因而在 context/provider 前
   明确拒绝 `nb-*` 等导入 ID，避免完成 OCR 后才落入泛化 persistence failure。纯 selection adapter 仍保留
   imported ID 的 provider-order 语义，二者职责不混淆。
4. provider 返回后重新读取 page/generation/fingerprint；迟到结果不提交。
5. coordinator 不分配 DELETE/CREATE/INSERT identities，不移动 Undo/Redo，不修改 selection/UI。
   新 Text identity、三步 transaction、source payload byte compare 仍由
   `commitOriginalHandwritingConversion()` 独占。
6. 任一失败都只返回 outcome，不声称成功；调用方必须只在 `SUCCESS` 后刷新页面/历史。

## 4. 明确边界

本阶段没有新增 SelectionOverlay 菜单、真实 OCR provider、CoreVision 伪装适配、错误 toast 或设备体验
验收。Harmony 当前仍没有可证明等价的 stroke-native 生产 provider，因此“手写转文字已上线”仍不得宣称。
本 evidence 只证明底层编排和结果门禁安全可接入，`T-042` APK 版本追踪继续保留为整个 Goal 最后一项。

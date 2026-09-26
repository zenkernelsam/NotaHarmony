# ADR-0746：RemoteConfig 特性开关面登记与默认姿态对齐

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-802-remoteconfig-flags.md`
- Replay：`docs/migration/replays/d02-remoteconfig-flags.mjs`

## 决定

原版特性开关面登记为版本差异证据；Harmony 侧不引入 RemoteConfig 等价物，
对默认关的后端绑定特性继续执行 fail-closed——与原版默认姿态一致。

## 依据

RemoteConfig 默认表（`core_remoteconfig__remote_config_defaults.xml`）是特性
门的最硬证据：

- 1.4.2 新增 32 个开关，其中**几乎所有面向用户的新特性默认 `false`**
  （gallery/calendar/FinishNotes/shape/text-only/typing-settings/HWR 三件套/
  差异化手机 UX 等），即服务端灰度控制。
- 共享 26 个开关默认值零翻转——1.0.3 默认行为在 1.4.2 未变。
- 移除的 26 个开关对应特性仍在（字符串面获证），为毕业内置而非下线；
  `NoteLimit→StarterNoteLimit` 与 `feature_settings→ui_account` 同模式，
  属"改名重构"第三次实例。
- 三档订阅 offer ID（Lite/Plus/Pro × Annual/Monthly）默认空——定价由服务端
  下发，客户端无可移植逻辑；`Lite` 档为 1.4.2 新增。

## 影响

- 证明 NotaHarmony 移植的功能面在原版均已毕业为稳定内置面，基线选择正确。
- 默认关的后端绑定面（gallery/calendar/FinishNotes/订阅三档）在原版默认
  体验中等价缺席，Harmony fail-closed 不构成默认体验损失。
- `androidImageBlockOcr`/`androidImeSessionTelemetry` 默认开：前者属 ML Kit
  proprietary 边界，后者为遥测（无用户功能语义）。
- `androidRuler` 例外：1.0.3 无门内置→1.4.2 加门默认关——直尺在两版间从
  "恒开"变为"服务端控制"，Harmony 已按 1.0.3 内置语义实现，保留。

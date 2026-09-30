# ADR-1304 — 复制确认 Toast 措辞保真（Copied-X 语序）

## 状态

Accepted（已落地）。

## 决策

对齐原版 `feature_note__copied_link`="Copied Link" 的 `Copied X` 语序：
- `link_copied` `Link copied`→`Copied Link`
- `note_id_copied` `Note ID copied`→`Copied note ID`（一致性）

zh 已是自然语序，不改。

## 刻意不改

- `new_note`/`crop_reset`/`crop_confirm` 等：语境为速拨 chip / 无障碍描述，
  非原版主按钮/短标签语境。
- 88 个 `feature_*` 缺失键：经逐点核对多为 fail-closed 特性，非可恢复缺陷。

## 依据

- 证据：`docs/migration/evidence/phase-1363-copied-toast-wording.md`
- Replay：`d02-copied-toast-wording.mjs`（10/10）

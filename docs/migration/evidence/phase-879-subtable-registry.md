# Phase 879 证据 — 余子表登记（akb/dp5/qqe/z1d/m2d/lxc）

## 目的

关闭 875 遗留的六张子表——以 toString/访问器实证字段语义
（`decompiled_1.0.3/sources/defpackage/`）。全部 `extends
cee implements ka4`。

## 字段契约（toString 实证）

| 类 | 实体 | 字段 |
|----|------|------|
| `akb` | `RecordingAsset` | `metadata: wa0`（j()）——录音的资产引用（wa0=PDF/资产字段表） |
| `dp5` | `ImageAsset` | `metadata: wa0`（j()）、`size: qed`（k()）——图像块资产+尺寸 |
| `qqe` | `TextSelection` | `anchor: cxc`（k()）、`focus: cxc`（l()）——双位置选区 |
| `z1d` | `SetBool` | `value: Boolean`（j()）——布尔 setter 包装（l2d 用） |
| `m2d` | `SetPageBackground` | `value: nz9`（j()）——页背景 setter 包装（ge8/td8 用） |
| `lxc` | `SeqMove` | `toId: cxc`（j()）——序列移动目标（ge8 moveTo） |

## 语义锚点

- `m2d`/`lxc`/`z1d` 是 setter 包装族（与 874 `?2d` 族同构：
  单字段 change-wrapper）：`ge8` MODIFY_PAGE 的
  moveToIndex→`egh.a(cxc)`→lxc、background→m2d；`l2d`
  SET_METADATA 的布尔槽→z1d——实测 `me8` MODIFY_STYLE 使用
  z1d 布尔 setter（`v()`/`u()`/`t()`），`l2d` 自身布尔槽为
  裸 Boolean + `m2d` 背景 setter。
- `u5j.s` 中 `Integer` 页索引经 `bfj.b` 派生 cxc 再
  `egh.a` 包 lxc——`SeqMove{toId}` 即页移动目标的线形式。
- `qqe` 双 cxc = 文本选区 anchor/focus（he8 段落样式范围
  用 exc 对，qqe 是另一种选区载体——peer/selection 相关）。
- `akb`/`dp5` 复用 `wa0`（PDF-in-asset 表，867 登记）作
  资产元数据——资产引用模型统一。

## Harmony 侧

- `OriginalModifyPagePayloadEncoder`：moveTo/backgroundWinner
  与 SeqMove/SetPageBackground 语义对应。
- `OriginalRecordingOperation`/`PageRepository`：RecordingAsset
  经 wa0 引用对应 Harmony 资产登记；ImageAsset 的
  metadata+size 与 ImageBlock 几何/asset 键对应。
- z1d SetBool 与 SET_METADATA 布尔槽对齐。

## 结论

875 遗留六子表全部实名登记；setter 包装族闭合（`?2d` 单
字段 + z1d/m2d/lxc 语义命名）。纯文档+fixture 阶段。

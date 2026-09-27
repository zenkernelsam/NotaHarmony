# Phase 877 报告 — `haj` 助手与 Kotlin 默认掩码

## 范围

解开 `u5j`/`haj` 工厂末位 int 语义（876 遗留问题）；登记
`haj` CreatePage 助手族。纯审计，无源改动。

## 原版发现

- 末位 int = Kotlin `$default` 位掩码，位 = 参数序号 2 次幂；
  `u5j.s` 为 `x09` 扩展（receiver 不占位）。
- `haj.a` 掩码表：bit0→location=null、bit1→background=null、
  bit3→bookmark=UNBOOKMARKED；pageCount@2 无默认；bit4(16)
  恒置位→参数序号 4 被 JADX 省略（类型推断失败），线格式
  仅 C(4) 字段。
- `haj.a` 调用点：wz9.u(16 复制页)、te0/kp5/eca(16)、
  nx6/zm7(27 全默认双页)、zm7(26)。
- `haj.c` = ln2 再序列化器（qee 写侧）；`haj.b` = 无关
  Compose UI 同名巧合。
- `ln2` 字段 toString 实证：pageCount=mmf 包装 int 默认 1。
- 派生默认：f 固定 SQUARE/PIXEL_ALIGN、丢 qed(1,1)；
  j 默认 t16=FIXED_WIDTH。

## Harmony 核对

`OriginalCreatePagePayloadEncoder` 与 `haj.a` 线格式一致
（pageCount 默认 1、bookmark oz9、已引原版符号）。

## 产出

- 证据：`phase-877-haj-default-mask.md`
- Fixture：`d02-haj-default-mask.mjs`（30/30）
- ADR-0821；全量 Replay 与双 HAP 结果记录于提交。

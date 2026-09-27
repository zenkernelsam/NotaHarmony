# ADR-0821 — `haj` CreatePage 助手与 Kotlin `$default` 掩码语义

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `haj.a(cxc?, nz9?, pageCount:Int, oz9=UNBOOKMARKED, p4=?)`
  = `ln2` 构造器；末位 int 为 Kotlin 默认参数**位掩码**
  （位=参数序号幂）。`&1/2/8` 分别默认 location/background/
  bookmark；pageCount@2 无默认（恒显式传 1|2）；bit4(16)
  恒置位→参数序号 4 被 JADX 省略（文件类型推断失败所致），
  线格式仅 C(4) 字段，p4 非线可见。
- `haj.c` = `ln2` 再序列化器（`qee` 写侧分发）。
- `haj.b` = 无关 Compose UI（混淆同名）。
- `u5j` 全部末位 int 同为掩码：`s` 为 `x09` 扩展（receiver
  不占位→num&m2d&oz9=bit1/2/3），`i`/`f`/`j`/`q`/`x` 为普通
  函数（x09@0 占位）；`l` 用 `i2 != 0` 整体判定。
- 派生默认：f 固定 ty0.SQUARE/PIXEL_ALIGN 且丢 qed=(1,1)；
  j 默认 t16=FIXED_WIDTH。
- `ln2` 字段实证（toString）：location@0、background@1、
  pageCount@2(mmf)、bookmarked@3。

## Harmony 决策

`OriginalCreatePagePayloadEncoder` 字段与默认值与 `haj.a`
一致（pageCount 默认 1、bookmark oz9、注释已引 haj.a/wz9.u）。

## Parity 状态

等价（掩码语义仅影响原 API 默认值解析，不改变线格式）。

## 验证

- `d02-haj-default-mask.mjs`：30/30 通过。
- 全量 Replay 与双 HAP 构建见 Phase 877 提交。

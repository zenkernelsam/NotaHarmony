# ADR-0013：原版 legacy Ink nib 字段兼容语义

- 状态：Accepted
- 日期：2026-08-10
- 关联：D-02、数据库 v34、ADR-0004、ADR-0012

## 背景

Android 1.0.3 的 CREATE_INK `dm2` 在 field 16/17 保存 `nibAngle` 与
`nibFlatness`，MODIFY_INK `wd8` 在 field 14/15 保存相同字段。两者类型均为
`ymf`；`ymf.compareTo()` 使用 `value & 65535`，因此 wire value 必须按 unsigned
16-bit 解读，不能把大于 32767 的值变成负数。

这些字段仍出现在 FlatBuffer value object 的 equals、hashCode 和 toString 中，
但不属于 Android 1.0.3 的 Ink 状态模型：`q06` 构造时没有读取 `dm2.q()/r()`，
`q06.java:573-630` 应用 MODIFY_INK 时也没有读取 `wd8.q()/r()`；`d16` 没有对应
register，`s06` 与 renderer 也没有消费路径。由此不能把字段存在误判为书法笔尖
渲染能力。

## 决策

1. CREATE_INK field 16/17 与 MODIFY_INK field 14/15 均使用 `readUint16()` 解码，
   payload 暴露 nullable number，保留 field 缺席与数值 0 的区别。
2. 接收的完整 raw synced operation 继续原样保存在 inbox，保证转发、诊断和未来
   版本兼容不丢字段。
3. nib 字段不写入 `StrokeElementData`，不建立数据库列或 LWW winner，也不参与
   Canvas、缩略图、选择、擦除、剪贴板或 Undo。
4. nib-only MODIFY_INK 是正常 APPLIED no-op：inbox 状态和连续 cursor 在同一事务
   前进，页面 snapshot、revision、搜索索引和本地 operation log 均不变化。
5. 其他不受支持字段的 DEFERRED 门禁保持不变。未来只有在找到原版其他版本的明确
   状态与渲染证据后，才能另立 ADR 扩展 nib 行为。

## 后果与验证

- `d02-legacy-ink-nib.mjs` 覆盖 CREATE/MODIFY 字段、65535 与 40000 两个 unsigned
  边界、raw op 保留、nib-only APPLIED no-op、事务回滚和数据库 v34 不变。
- ArkTS FlatBuffer fixture 覆盖相同字段与边界，并断言它们不触发 unsupported gate。
- 全部 26 个 D-02 桌面 replay 通过；clean 后 `note@ohosTest` 与 `note@default`
  assembleHap 均 BUILD SUCCESSFUL，仅保留既有 warning。
- 未启动设备或执行 Hypium。本 ADR 只关闭 legacy nib 兼容语义，不关闭
  Pencil/Tape/effects、后续 block/text payload、完整 MODIFY_INK 或 D-02。

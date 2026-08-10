# ADR-0016：原版 Block position-lock LWW 与编辑保护

## 原版证据

Android 1.0.3 的 `ry0` 把 `positionLocked` 保存为 Block common 的独立 LWW register；
`qy0.c()` 对 `MODIFY_BLOCK td8.u()` 单独调用 register apply。`cie.t()` 将该 winning
值暴露给 TextBlock。`jrh.a()` 是 Block/Shape 的统一锁定判断，`avc` 在选区变换前过滤
锁定实体，`fu1.b()` 在编辑集合中移除锁定实体，`nfh.b()` 则把锁定状态带入 selection data。

因此 `positionLocked` 不是只需保存的不可见元数据。Harmony 若推进 synced inbox cursor，
必须同时让 snapshot、命中、选区、橡皮和文本编辑尊重该值。

## 决策

1. `TextBlockElement.positionLocked` 使用可选 boolean。旧 Harmony JSON 没有该字段时按原版
   CREATE 默认 `false` 解释；新建本地文本显式写 `false`，clone/导入导出保留该值。
2. `CREATE_BLOCK` 的 TEXT 子集不再拒绝 `positionLocked=true`，同时写入
   `original_block_state.create_position_locked` 与文本 snapshot。
3. `MODIFY_BLOCK` 开放 `positionLocked` 这一组 common LWW。CREATE 值只是无 winner fallback；
   首次较小 op 可获胜，旧/相等 op 不覆盖，寄存器与 snapshot 仍由 inbox 外层事务原子提交。
4. 锁定文本不进入 Harmony 编辑选区，不接受选区 transform，不接受对象橡皮命中，也不能
   通过文本工具进入编辑。当前 UI 尚未产生本地原版 MODIFY_BLOCK，因此不提供会绕过同步
   identity/register 的本地“解锁”写法。
5. `corner`、`textWrap` 与 `enableCaption` 继续 DEFERRED。前两者依赖完整 Block/RichText
   layout，caption 依赖 IMAGE caption rich text；只存 register 后推进 cursor 不构成功能支持。

## 验证边界

- `d02-create-block.mjs` 覆盖 create-time locked snapshot。
- `d02-modify-block-common.mjs` 覆盖 position-lock winner、较小首次获胜、stale no-op、payload
  同事务更新，以及 selection/eraser/package consumer 的源码契约。
- `TextBlockGeometry.test.ets` 与 `SelectionTool.test.ets` 覆盖锁定块不变换、不命中和不入选区；
  测试源码通过 ohosTest ArkTS 编译。设备 Hypium 与真实同步 UI 刷新仍待设备验收。

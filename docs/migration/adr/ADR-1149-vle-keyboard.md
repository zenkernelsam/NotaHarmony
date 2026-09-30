# ADR-1149：vle 键盘/IME 层（Back 提交语义）

## 状态

已接受（Phase 1205）。

## 决策

- `vle.o` Back 提交（编辑态时提交待决组合 + 退出
  编辑，消费返回键）→ Harmony `onBackPressed` 拦截
  同语义。
- `hld`/`v52.r`/`etd` 服务令牌键盘控制器 → Harmony
  `@Provide/@Consume` 或显式注入。
- `dli.b` ActionMode 刷新 → Harmony 文本选区菜单
  重算。

## 理由

`dli.a` = KEYCODE_BACK+UP；`vle.o` =
`qoe.a(…,bme.I)` 提交 + `joeVar.y(false)` 退编辑；
`o1()` `aa6.v(this,v52.r)` 令牌查找 + "No software
keyboard controller" 告警。

## 后果

Harmony 编辑器 Back 行为 = 编辑态提交输入+退编辑
（不退出页）—— 与原版语义一致。

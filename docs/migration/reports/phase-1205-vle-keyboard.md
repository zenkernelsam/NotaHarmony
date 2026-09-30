# Phase 1205 报告 — vle 键盘/IME 层

## 完成内容

- `vle.o(KeyEvent)` = Back 键提交待决组合 +
  选区坍缩 + 退出编辑（消费 Back）；
- `dli.a` = KEYCODE_BACK+UP 判定；
- `o1()→hld` 软键盘控制器 + `v52.r`/`etd` 服务令牌；
- `p1` 键盘协程、`r` no-op 槽、`t0` `ple` 派发。

## 产出

- evidence `phase-1205-vle-keyboard.md`
- fixture `d02-vle-keyboard.mjs`（10/10）
- ADR-1149

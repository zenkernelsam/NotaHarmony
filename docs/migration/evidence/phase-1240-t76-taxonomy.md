# Phase 1240 证据（里程碑）— t76 事件分类学全景（生成↔消费图）

来源：`defpackage` 全 `new <event>(` 生成点普查。

## 事件图（start↔end 配对）

| start | end | 生成者 | 语义 |
|-------|-----|--------|------|
| `rj5` | `sj5{rj5}` | j2/bk5/k2 | 笔/触摸按下-抬起 |
| `zo4` | `ap4{zo4}` | bq1 | 焦点/drag 起-止 |
| `ll3` | `ml3{ll3}` | qle→vle | 编辑会话起-止 |
| `mn3` | `nn3{mn3}` + `ln3{mn3}` | gn3 | **1:2** 橡皮/手势起 → 双终态 |
| `fwa{long}` | `gwa{fwa}` + `ewa{fwa}` | k2/g2/i2/b14 | **1:2** 计时长按起 → fire/cancel |

## 结构

- **start 事件**无载荷（`rj5`/`zo4`/`ll3`/`mn3` singleton；
  `fwa{long ts}` 计时）;
- **end 事件**包对应 start（`sj5{rj5}` 等）→ `ww0`/
  `e71` 出栈 `((end).a)`;
- **1:2 终态**（`mn3→nn3+ln3`、`fwa→gwa+ewa`）=
  成功-vs-取消 / fire-vs-释放 二分；
- `hwa`（fwa/gwa/ewa 的 iface）= 计时分类；
- 消费：`ww0`（权重动画）、`e71`×8（事件集扇出）、
  `bq4`/`ls`（relay/对账）。

## 语义

`t76` = 编辑器**触摸手势生命周期事件总线** ——
down/up 配对驱动触觉权重、手势状态机、edit 会话
边界。

## Harmony 决策

t76 事件总线 → Harmony `onTouch`/`gesture` 回调 +
自研事件栈 —— 手势生命周期语义保真。

## 产出

- fixture `d02-t76-taxonomy.mjs`（10 断言）。
- ADR-1184；中文报告。

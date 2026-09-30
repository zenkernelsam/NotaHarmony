# ADR-1070：SharedNodeData + 可变锚

## 状态

已接受（Phase 1126）。

## 决策

- `f8d` = `SharedNodeData{site,ts,audioTs,parent:qwc,values}` —
  序列树共享节点。
- `hr5` = 可变锚 `{J:site,K:ts,L:seq}` — `exc` 的出参变体。
- `f8d.a(hr5,i)` 写 `{site,ts,slot}`；`qwc/rwc.d` 委托。

## 依据

toString 实名 + 三字段锚写出 + 父游标。

## 后果

Harmony 序列节点 = site/ts/audioTs/parent/values；锚三
元组不可变为主、可变仅出参。

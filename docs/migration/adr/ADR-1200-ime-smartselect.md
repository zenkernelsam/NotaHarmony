# ADR-1200：IME + 智能选择

## 状态

已接受（Phase 1256）。

## 决策

`eje` 软键盘 Node+`yla` TextClassifier+`k6f` 会话 →
Harmony `TextInput`/`SelectController`+软键盘回调（或
fail-closed 实体识别）。

## 理由

`yla`=`TextClassifier.classifyText(selRange)` 智能选择
实体识别；`eje`=键盘 Node（`qie`+`k6f`+`cmb` 几何）
—— IME+智能选择。

## 后果

Harmony 智能选择 = SelectController+实体识别
（fail-closed）—— IME 语义保真。

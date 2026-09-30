# Phase 1256 证据 — eje/yla/k6f IME + 智能选择

来源：`defpackage/{eje,yla,k6f,qie,h6f,fn7,dqc}.java`。

## `eje` = 软件键盘 Modifier.Node

```java
eje extends n73 implements q52, qie {
    k6f Y;                  // IME 会话
    ix4 Z,a0,b0;            // 3 键盘回调
    tqd c0;                 // job
    cmb e0;                 // 键盘几何
    W()→pie; m/q(mv6)→geometry
}
```

## `yla` = TextClassifier（智能选择）

```java
yla { Context b; dqc c; fn7 d; TextClassifier f;
    a(charSeq, selRange, classifier, cb):
        classifier.classifyText(
            new TextClassification.Request.Builder(
                charSeq, jqe.g(sel), jqe.f(sel)
            ).setDefaultLocales(b()).build());   // 实体分类
}
```

## `k6f` = IME 会话 holder `{eje a, h6f b}`

## 语义

- `eje` = 软键盘节点（`qie` 键盘 controller + `k6f`
  会话 + `tqd c0` job + `cmb` 几何 + `m/q(mv6)` 位置）；
- `yla` = **`TextClassifier`** —— 长按/双击时的智能选择：
  `classifyText(selRange)`→`TextClassification` 识别链接/
  日期/地址等实体（Smart Select 弹出操作）;
- `jqe.g/f` = TextRange start/end；
- `k6f`/`h6f` = IME 会话 + 键盘模式枚举；
- `em8`/`p6a` = 分类结果流 + state。

## Harmony 决策

TextClassifier → Harmony `TextInput`/`SelectController`
或自研实体识别（fail-closed）；`eje` 键盘节点 →
软键盘回调+insets。

## 产出

- fixture `d02-ime-smartselect.mjs`（10 断言）。
- ADR-1200；中文报告。

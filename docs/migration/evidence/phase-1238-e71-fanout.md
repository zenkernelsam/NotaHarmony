# Phase 1238 证据 — e71 t76 事件集扇出（8 消费者）

来源：`defpackage/{e71,ol4,ekd,t76,rj5,sj5,zo4,ap4,fwa,gwa,ewa}.java`。

## `e71 implements ol4` = 共享模式事件集维护器

```java
public final /* synthetic */ int I;      // case 索引 (0-7)
public final /* synthetic */ ekd J;      // 该消费者的列表

e71(ekd, int i) { J=ekd; I=i; }

emit(obj, ef2) {
    switch (I) {                          // 8 case
    case 0:
        if (rj5) ekd.add; else if (sj5) ekd.remove(sj5.a);
        else if (zo4) ekd.add; else if (ap4) ekd.remove(ap4.a);
        else if (fwa) ekd.add; else if (gwa) ekd.remove(gwa.a);
        else if (ewa) ekd.remove(ewa.a);
    case 1: // 同模式 另一 ekd
        if (rj5) ekd.add; else if (sj5) ekd.remove(sj5.a);
        ...
    }
}
```

## 语义

- `e71` = **模板化的事件集扇出** —— 同一 add/remove
  配对模式实例化 8×，每 case 把 `t76` 子集收进不同
  `ekd` 列表；
- `I` case 索引 → 该消费者追踪的事件子集；
- 含 `fwa`/`gwa`/`ewa` **计时事件对**（down/up + timer）；
- 每 `ekd` 喂一个手势状态机 —— **8 消费者各维护
  自己的活跃事件集**。

## Harmony 决策

`ol4`+`ekd` 事件集扇出 → Harmony `Flow` collect +
ArrayList 状态集 —— 手势集语义保真。

## 产出

- fixture `d02-e71-fanout.mjs`（10 断言）。
- ADR-1182；中文报告。

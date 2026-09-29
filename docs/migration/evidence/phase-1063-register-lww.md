# Phase 1063 证据 — Register LWW 语义 + opId 全序

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `fqb` Register$Builder（真名 `crdt.Register$Builder`）

```java
{qo5 a 胜方 opId, Object b 值, xgb c 时间戳}

void c(uq9 op, Object v) {
    qo5 l = op.l();
    long t = fsi.J(op);
    if (a == null || so5.a(l, a) > 0) {   // 新 op 更大才覆盖
        a = l; b = v; c = new xgb(t);
    }
}
yc6 a();  // 快照 {qo5 J, Object K, xgb L}
boolean b();  // isSet
```

= **LWW Register**：按 opId 全序，大者胜（收敛）。

## `so5.a(qo5, qo5)` = opId 全序比较器

```java
return d()==d2 ? ba6.w(c()&0xffff, c2&0xffff)
               : Integer.compareUnsigned(d(), d2());
```

- 先 **logicalTime**（int，`compareUnsigned` 无符号），
  再 **site**（short，`&0xffff` 无符号）——
  Lamport-then-site 全序，确定性收敛。
- 与 Phase 1060 无符号族呼应（qo5.c()=site,d()=time）。

## `fsi.J(uq9)` = 寄存器时间戳

`serverTime(tmf.I)` 优先，缺省 `clientTime(k())`——
服务端时间优先于本地时间（权威时钟）。

## `yc6` = Register 快照（不可变）

`{qo5 winnerId, value, xgb time}`——builder→快照分离。

## Harmony 决策

- **LWW 写语义原样保留**：compareUnsigned(lt)+
  unsigned short site；寄存器存胜方 opId+值+时间戳。
- 时间戳 serverTime 优先。

## 产出

- fixture `d02-register-lww.mjs`（11 断言）。
- ADR-1007；中文报告。

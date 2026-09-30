# ADR-1182：e71 事件集扇出

## 状态

已接受（Phase 1238）。

## 决策

`e71(I,ekd)` 8-case 事件集扇出 + fwa/gwa/ewa 计时对
→ Harmony Flow collect + ArrayList 事件集。

## 理由

`e71` 模板化扇出：每 case 把 t76 子集（rj5/sj5/zo4/
ap4/fwa/gwa/ewa）收进不同 `ekd` —— 8 消费者各维护
活跃事件集喂手势状态机。

## 后果

Harmony 事件扇出 = Flow collect+事件集 —— 手势集
语义保真。

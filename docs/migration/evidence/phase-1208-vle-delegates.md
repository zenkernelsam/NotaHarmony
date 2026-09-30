# Phase 1208 证据 — vle 委托架构（bq4/ol3/u8e/xp4 子组件树）

来源：`defpackage/{vle,bq4,ol3,ame,ew,u8e,pg0,u6g,tqd,pl3,kl3,ql8,xp4}.java`。

## `vle` 内部状态（ctor 接线）

```java
joeVar.l = new ple(this,3);          // 回注 joe
i0 = new bq4(wj8, new qle(this,0),2);// ← t76 通道消费者
j0 = new u8e(null,null,j74(this,10)); // 输入栈
l0 = new ol3(new ew(5, crb(ple,27),
    new ame(qle×5)),1);               // ← 5 路手势派发
o0 = new pg0(11); p0 = new tle(this);
q0/s0 = qle/ple 动作; t0 = MutableState(false);
```

## 子组件 = od8/n73 子 ViewModel + Compose 节点

| 组件 | 角色 |
|---|---|
| `bq4 extends n73 implements mvc,o65,q52,sn9,vff` | **子控制器**——承接 vle 的 4 iface（语义/选择/媒体/生命周期），`xp4 d0` |
| `ol3 extends od8 implements vff,pl3,kv6` | 指针输入控制器（`ew`/`ame` 包装） |
| `ame implements pl3` | **5-lambda 指针处理**（`qle`×5 = tap/双击/长按/拖动/滚动回调） |
| `u8e extends od8 implements bra,r93,ara` | Density 感知输入控制器（`ql8` 事件槽×3） |
| `pl3` | **指针事件 iface**：`F/P0/k0/u0/w0/x(kl3)` = Compose PointerInput 回调 |
| `ql8 implements RandomAccess{Object[]}` | Object[] 事件列表 |
| `xp4 extends od8 implements q52,kv6,sn9,rd8,j73` | **Compose Modifier.Node**：`instanceof rd8` 遍历 `od8` 树收集 `qz6` |
| `pg0 implements cx3,sr6,ejd` | Compose 持久集合（MutableVector） |
| `tqd extends s2` | 协程 Job ×2 |

## 判定

`vle` 是 **facade ViewModel**：把 11 能力 iface 委托给
`od8`-树子组件——`bq4`（semantics/selection）、`ol3`+
`ame`/`pl3`（指针输入 tap/drag/scroll）、`u8e`（Density
输入）、`xp4`（Modifier.Node 树遍历派发）。编辑器 =
**Compose Modifier.Node 组合树** + ViewModel 编排。

## Harmony 决策

`od8` 子节点 + iface 能力遍历 → ArkUI 自定义组件 +
`@Observed` 服务分组 + `componentUtils` 树查找。

## 产出

- fixture `d02-vle-delegates.mjs`（10 断言）。
- ADR-1152；中文报告。

# Phase 1019 证据 — ssf 鉴权/会话服务

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ssf` = 鉴权/会话服务

```java
public final class ssf {
    public final q75 a;      // ?
    public final xrf b;      // 鉴权后端 client
    public final vs4 c;      // ?
    public final pce d;      // lazy
    public final sfb e;      // 会话状态 Flow
    public final yrd f;
    public ssf(q75, xrf, vs4, cx6);
}
```

## 方法

| 方法 | 形态 | 推断 |
|---|---|---|
| `a(ff2)` | suspend | 会话初始化/拉取 |
| `b() → ml4` | 返回 `e` | **会话状态 Flow 暴露** |
| `c(ff2, ix4, String)` | suspend | 内部复用 |
| `d(String, c8c, String, String, ff2)` | suspend | 4-arg 鉴权调用 |
| `e(String,String,ff2)` | 349-inst（fail） | 鉴权对（userId+token?） |
| `f(String,String,ff2)` | 321-inst（fail） | 同上，调
  `xrf.g(str,str,str)` |
| `g(ff2)` | suspend | 收尾 |
| `h`/`i` | suspend | 更多鉴权路 |

- `f` 残块：`this.b.g(r2, r1, r14, r0)`——
  `xrf` 三 String 调用（鉴权端点）。
- `ml4` = **接口**——会话状态类型。

## 角色

`ssf` = nr1 的**鉴权/会话门**：同步前后向 `xrf`
发起 (String,String) 形态的认证/刷新调用，经 `b()`
暴露 `ml4` 状态 Flow。`e`/`f` 本体反编译失败——
签名+下游调用点可证。

## HarmonyOS 决策

- 鉴权流程整体 **fail-closed**（Google/Microsoft
  OAuth + 服务端 token 不可在 Harmony 复现）；
- 本地保留 `ml4`-形态状态 Flow 的等价物
  （authenticated/refreshing/expired）。

## 产出

- fixture `d02-ssf-auth.mjs`（10 断言）。
- ADR-0963；中文报告。

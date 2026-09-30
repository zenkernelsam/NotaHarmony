# ADR-1205：a46 输入变换链

## 状态

已接受（Phase 1261）。

## 决策

`a46` InputTransformation+`bg4` `.then`+`d28` maxLength+
`nv1` hex+`z36` passthrough → Harmony `TextInput`
`onWillChange`/`inputFilter`+变换链。

## 理由

`a46`=输入变换 iface（`i(dle)`）；`bg4`=`.then` 链；
`d28`=`.maxLength(6)`；`nv1`=hex 过滤器；`z36`=恒等 —
— 字段输入规则组合。

## 后果

Harmony 输入过滤 = onWillChange+inputFilter+变换 —
— 变换链语义保真。

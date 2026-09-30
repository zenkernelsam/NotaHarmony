# ADR-1164：a46 = InputTransformation 链

## 状态

已接受（Phase 1220）。

## 决策

`a46` Compose `InputTransformation`（`bg4`.then /
`d28`.maxLength / `nv1` hex / `z36` passthrough）
→ Harmony `onWillChange` 过滤器链（组合+限长+
字符集校验+回滚拒绝）。

## 理由

`d28.toString`="InputTransformation.maxLength(6)"
实名；`bg4`="a.then(b)"；`nv1`=`#`+hex 校验；
拒绝=`c(0,len,原)`+`f(sel)`+`w()` 回滚。

## 后果

Harmony 输入过滤 = 可组合变换链 + 回滚语义 —
对齐 Compose InputTransformation。

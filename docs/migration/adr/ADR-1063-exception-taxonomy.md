# ADR-1063：core/ 异常谱系

## 状态

已接受（Phase 1119）。

## 决策

- 网络异常三分类：`HttpStatusException{code,…}` /
  `NoConnectivityException` / `NotAuthenticatedException` →
  IOException 系。
- `CopyPasteException` = sealed 5 变体（MissingPosition/
  IncompatibleContent/Consistency/InvalidArguments/ConcurrentPaste）。

## 依据

未混淆 `@Metadata` Kotlin 注解枚举全部子类。

## 后果

Harmony：BusinessError 码映射 + sealed error union；
复制粘贴 5 失败模式保留原名语义。

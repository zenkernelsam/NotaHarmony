# ADR-1058：HAMT 持久集合内部

## 状态

已接受（Phase 1114）。

## 决策

- `lgf` = HAMT TrieNode `{bitmap, Object[], f16 令牌}`，
  `f16` = MutabilityOwnership。
- 只读基 `m2`/`n5`/`y3`/`zr5`；`hw3` 空列表单例。
- kotlinx immutable-collections vendored 全栈。

## 依据

`lgf.f` = TrieNode.mutablePut；令牌控 builder 期原位改。

## 后果

Harmony：结构共享 Map/trie 复刻；builder 期令牌模式
可用版本戳近似。

# Phase 896 证据 — `zac` 会话基类 + 序列化注册基建

## 目的

实名会话生命周期基类与 zwd/ree 派发的注册基建。
`decompiled_1.0.3`。

## `zac` = 会话基类（Closeable）

```java
public abstract class zac implements Closeable {
    public final AtomicBoolean I = new AtomicBoolean(false);
    public abstract void a();                    // 子类关闭体
    close()  { if (I.compareAndSet(false,true)) a(); }
    finalize(){ if (I.compareAndSet(false,true)) a(); }  // 兜底
}
```

- **幂等关闭**：AtomicBoolean CAS 保证 `a()` 恰好一次；
  `close()` 与 `finalize()` 双路径（GC 兜底）。
- `tzc`（883 编辑会话）继承 → 会话生命周期 =
  幂等 close + finalize 兜底契约。

## `npb`/`mpb`/`wx4` = 序列化注册基建

- `npb` = kotlin-reflect 运行期类键工厂：
  `b(Class)→oj6`（KClass 键）、`a/c/d/e/f` 类型包装。
  `zwd.a` 内 `npbVar.b(cls)` = 结构类→KClass 注册键。
- `mpb` = 提供者：静态块优先实例化 `opb`（反射实现），
  失败回落基础 `npb` —— **注册键的惰性反射入口**。
- `wx4` = Kotlin **Function2** 接口 `invoke(o,o)`——
  注册表值的序列化 lambda 类型（`(xwd,builder)→offset`）。

## zwd.a/ree 派发全貌（回填 861/889）

`{KClass → Function2}` 注册表：`npb.b(cls)` 键 →
`map.get` → `wx4.invoke`；缺失 → `rgc.b`+抛（fail-closed）。

## Harmony 侧

会话层 ↔ Harmony 编辑器会话生命周期（dispose 幂等）；
结构/表派发 ↔ Harmony 手写编码器的类型分派
（编译期 switch，无反射——行为等价，fail-closed 对齐）。

## 结论

会话幂等关闭契约 + 注册派发基建实名；wire 层
读写+校验+生命周期三层闭合。纯文档+fixture 阶段。

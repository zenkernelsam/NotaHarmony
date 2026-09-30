# Phase 1285 证据 — GLMathNative 数学渲染 + SharedMemoryByteArena

来源：`core/glmath/{GLMathNative,GLMathTextMeasurer,
MathDrawTarget}.java` + `core/common/memory/a.java`。

## `GLMathNative` = **原生 LaTeX→GL 数学渲染**（libglmath.so）

```java
System.loadLibrary("glmath")
nativeInit(resPath)→boolean             // 初始化（TeX 资源路径）
nativeMeasure(latex,width,fontSize)→float[]  // LaTeX 度量
nativeDraw(latex,w,h,fontSize,argb,MathDrawTarget)→boolean
                                         // LaTeX→GL 绘制目标
```

→ 数学公式 = **原生渲染引擎**（TeX 排版→OpenGL draw
target）—— 笔记内嵌数学公式的绘制管线。

## `GLMathTextMeasurer` = 文本度量

`measure(text, fontFile, fontStyle, fontSize)→float[]` —
— 数学文本字体度量（喂给 native 排版）。

## `MathDrawTarget` = GL 绘制目标 iface（native 回调写顶点）。

## `SharedMemoryByteArena` = **Android SharedMemory 分配器**

```java
a implements AutoCloseable {
    SharedMemory.create(I name, iMax).mapReadWrite()
        → ByteBuffer Q (direct, ordered)
    ArrayList N alloc 跟踪; HashSet O; ReferenceQueue P
    b(i)→ByteBuffer 分配; ArenaClosedException
}
```

→ 跨进程/大缓冲共享内存 arena（墨迹缓冲/资产传输
免拷贝）—— `SharedMemory`(ashmem) + 引用队列 GC 跟踪。

## 语义

- **LaTeX 数学公式** = 原生 `glmath` 排版→GL 渲染；
- **SharedMemory arena** = ashmem 直接缓冲分配器
  （大对象免 IPC 拷贝）。

## Harmony 决策

LaTeX 数学 → Harmony 无 `glmath` —— fail-closed：
KaTeX-JS/Web 渲染或系统公式组件；SharedMemory →
Harmony `SharedArrayBuffer`/Native Buffer —— 内存
语义部分保真，数学渲染降级。

## 产出

- fixture `d02-native-math-sharedmem.mjs`（10 断言）。
- ADR-1229（fail-closed 部分）；中文报告。

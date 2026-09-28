# Phase 962 报告 — z0c 写器函数全映射

## 范围

z0c.java + yec.java。纯审计。

## 原版发现

- `z0c` = synthetic Function0；case21/24 = 双注册表构建。
- λ 归并 `yec`/`ywd` 共享类 + `switch(序数)` λ 判别。
- **15 结构写器函数全名**（apb.Y/Z=fqa/qed、rh8.O=qo5、
  nti.X=cxc、wtf.b=utf、vfj.d=xq3…）。
- **23 表写器函数名**（tsi.c=uf7 → j7j.c=sw9）。

## 产出

- 证据：`phase-962-z0c-writer-map.md`
- Fixture：`d02-z0c-writer-map.mjs`（43/43）
- ADR-0906；全量 Replay 835 文件绿。

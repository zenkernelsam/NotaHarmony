# ADR-0031：原版 IMAGE 编辑生命周期

- 状态：Accepted（静态主画布编辑边界；缩略图与远端 CREATE 仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0028、ADR-0029、ADR-0030、M2-R-07～M2-R-09

## 原版证据

原版 1.0.3 `hp5` 同时实现 `be5` 与 `oy0`，因此 IMAGE 不是 renderer 特例，而是参与通用 Block 选择、变换、层序和
position-lock 合同的页面元素。`fu1.g/e` 对所有 `oy0` 先把命中几何变换到 block local space，再以 `oy0.a()` 的完整矩形
执行点选或套索命中；透明像素、crop 可见区和 bitmap 解码状态不改变对象命中范围。

`jrh.a(be5)` 对 `oy0` 返回 `oy0.t()`，原版 selection filter 会排除 position-locked Block。`hp5.u()` 的复制操作继续
携带同一 asset metadata、crop、URL 与水平/垂直 flip，不复制或改写资产身份；新对象身份由 Copy/Paste 操作层分配。

## 决策

IMAGE 进入与 Stroke、Shape、Text 相同的选择状态、统一 `PageElementOrder` 和编辑菜单。矩形选择使用 world bounds，套索使用
world bounds 中心；position-locked IMAGE 不可选择、变换或被对象橡皮删除。对象橡皮以完整变换后 block 四边形命中，覆盖单点、
路径穿越和笔宽半径；共线但相距很远的线段不能因方向值为零误判相交。

选区移动、缩放、旋转和翻转左乘 common transform，更新 `rotationRadians` 与 world bounds，但不改变 asset hash、metadata、
intrinsic size、crop、URL 或原版双 flip register。混合置前/置后保持四类元素内部相对顺序。

Copy/Cut/Paste 对 IMAGE 深复制 transform、bounds、hash words 和 crop，但继续引用同一 storage asset。Paste 与四类统一层序一起
原子加入内存；层序校验失败时四类数组共同回滚。新 ID 同时检查 Stroke、Shape、Text 和 IMAGE，跨页 Paste 后按现有 asset
loader 重新取得共享 bitmap。

`ERASE_ELEMENTS`、`ADD_ELEMENTS`、`DELETE_ELEMENTS`、`TRANSFORM_ELEMENTS` 的 Undo action 均携带 IMAGE 快照；删除索引、
源状态、ID 唯一性、成员集合和 element-order before/after 使用与其余元素相同的拒绝门。history 内存预算计入 IMAGE metadata。
只有增加、删除或恢复 IMAGE 成员时才刷新 bitmap 集合；纯变换、翻转和层序复用同一已解码资产。成组历史在整组落库成功后
刷新一次，失败则恢复旧页面后刷新一次，避免中间态异步 loader 越过事务回滚。

## Deferred 边界

本阶段仍不把 CREATE_BLOCK IMAGE 改为 APPLIED。远端页面/资产同事务 fixture、缩略图 IMAGE renderer、caption、GIF 动画、
ROUND corner 像素裁剪和网络 asset transport 尚未闭环。ROUND 半径继续等待原版运行态证据，不猜常量。

## 验证

- `d02-image-editing.mjs`：position lock、完整 block 命中、变换、对象擦除、深复制、四类层序、Undo 字段/预算、Paste 回滚和
  bitmap 仅在成员变化时刷新。
- `ImageBlockRendering.test.ets`：变换不修改资产/crop、locked no-op、单点/穿越/远距离共线擦除边界。
- `SelectionTool.test.ets`、`StrokeClipboard.test.ets`、`PageElementOrder.test.ets`：IMAGE 选择、深快照、新身份与四类层序。
- 全量 Node/SQLite replay：`TOTAL=40 FAILED=0`。
- `note@ohosTest` 增量 assembleHap：`BUILD SUCCESSFUL`；最终 clean 双构建见阶段报告。
- 未启动模拟器/真机，未执行设备 Hypium、真实菜单触控或图片变换像素验收。

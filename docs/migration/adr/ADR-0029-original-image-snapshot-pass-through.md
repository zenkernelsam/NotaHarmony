# ADR-0029：原版 IMAGE 页面快照 pass-through

- 状态：Accepted（页面保全边界；渲染与远端应用仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0028、M2-R-09、M2-F-03

## 问题

ADR-0028 已精确解码原版 CREATE_BLOCK IMAGE 的 asset metadata、intrinsic size、crop、URL 和双向 flip，但合法
IMAGE 仍不能写入页面。旧页面模型只有 Stroke/Text/Shape 三类消费者：全量保存会删除未知元素，统一 renderer 和缩略图的
兜底分支会把第四类元素强转为 Shape，持久化 Undo 在读取含 IMAGE 的删除页 checkpoint 时会把合法历史判成损坏。

原版 1.0.3 `hp5` 将 IMAGE 保持为独立 Block，并分别维护 crop、caption、web URL、水平/垂直 flip；GIF MIME 还进入独立
view type。`ry0` 的 common block 状态继续承载 transform、size、corner、textWrap、caption、position lock 和 z-index。
因此不能把 IMAGE 压成 Shape，也不能在 renderer 未完成时用占位 Shape 冒充原版结果。

## 决策

新增完整 `ImageElement`，其中 AssetHash 使用 8 个 uint64 十进制 word 的冒号串作为稳定键，禁止冒充 SHA-256；可变数组、
transform、bounds 和 crop 通过 `cloneImageElement()` 深复制，页面 bounds 从 block size 和 transform 重算。

`PageElementKind.IMAGE` 接入统一顺序、normalize 和 materialize。`StrokePersistence` 的加载、不可变入队快照、普通保存、历史组
保存和 BLOB codec 均保留 `{ kind: 'image' }`；`NoteCanvasView` 的初次加载、切页、失败回滚、保存、mutation replay、Undo
快照、数组同步和 ID 冲突检测均携带 IMAGE。删除页动作及持久化 checkpoint 同样物化 IMAGE，保证杀进程重启后的 Undo 历史
不会因第四类元素失效。

自有 `.note` v1 包允许第四类 typed payload。导入前严格校验 8 个 canonical uint64 word、稳定 hash key、非空文件名/MIME、
完整 uint32 fileSize、有限几何、crop、corner/textWrap、URL、flip 和 lock；导出与再导入保留原层序和 metadata。

IMAGE renderer 尚未建立前，主画布和缩略图只在 `SHAPE` 显式分支绘制 Shape，IMAGE 明确跳过，禁止错误强转。这个选择保证
普通落笔、文本编辑、Undo、切页、保存和导出不会毁掉图片数据，但不宣称图片已经可见或可编辑。

## Deferred 边界

CREATE_BLOCK IMAGE 继续返回 `CREATE_BLOCK_IMAGE_UNSUPPORTED`。进入 APPLIED 前仍必须闭环：AssetHash 到本地资产文件的事务映射、
缺失/损坏资产状态、静态 bitmap 与 GIF 生命周期、crop/flip/transform/corner renderer、选择/擦除/变换、caption、缩略图和远端
同事务 fixture。ROUND corner 的像素半径仍无原版静态证据，不猜常量。

## 验证

- `d02-image-pass-through.mjs`：四类混合顺序、IMAGE payload byte-stable、uint64/fileSize 精度，以及编辑器保存、mutation、包往返、
  删除页 checkpoint 和 renderer Shape guard 源码门。
- `PageElementOrder.test.ets`：IMAGE normalize/materialize 与混合 z-order。
- `StrokePersistence.test.ets`：中文文件名和完整 metadata BLOB 往返，不共享数组。
- `NotePackageSpec.test.ets`：合法 IMAGE、hash 不一致和 uint64 越界拒绝。
- `PersistentHistory.test.ets`：含 Stroke+IMAGE 的删除页 checkpoint 在 PUSH/UNDO/REDO 后可恢复。
- 全量 38 个 Node/SQLite replay 通过；clean 后 `note@ohosTest` 与 `note@default` 均完成 HAP 构建。设备 Hypium 未执行。

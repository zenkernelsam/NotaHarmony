# ADR-0788 — data 域异常分类学尾部归档

- 状态：已接受
- 证据：`docs/migration/evidence/phase-844-data-exception-taxonomy.md`
- 回放：`docs/migration/replays/d02-data-exception-taxonomy.mjs`（6/6）

## 决定

1. 原版 64 类类型化异常**全部归因**完毕（840/841/842/843/
   844 五相位分片闭合）。
2. 本相位归档剩余 32 类：backgroundwork、gallery、hwr×7、
   learn×2、library/state×8、loginstate×3、transcription×4、
   user×4、flatbuffers、fileimport。
3. 类型对齐 2 类（`InvalidFolderName`/`MaxFolderDepthExceeded`
   → Harmony `*Error`）；snapshot 域近似映射至
   `BackupPreparationError` 族；其余 fail-closed（依赖
   sync/后端/Play AssetDelivery/MyScript 等不可移植服务）。
4. Harmony 沿用泛化 `Error` 的导入/上传域不改写——文档化
   差异而非虚构类型层级。

## 后果

`com.gingerlabs.notability` 异常契约面**完整闭合**；
本地域关键校验（文件夹名/层级）已类型对齐。

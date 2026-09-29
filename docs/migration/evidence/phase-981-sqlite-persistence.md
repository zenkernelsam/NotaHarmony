# Phase 981 — SQLite/Room 持久层 + `gk4.v` qo5→long 打包

来源：`decompiled_1.0.3/sources/defpackage/{z7c,wp1,iq1,zp1,gk4}.java`

## 1. `z7c` = Room statement binder 接口

```java
void h0(int i, String);   // bindString
void l(int i, long);      // bindLong
void o(byte[], int);      // bindBlob
void q(double, int);      // bindDouble
void r(int);              // bindNull
void reset(); void w();
```

## 2. `zp1` = ClientOp 实体（op 字节入库路径）

```java
// wp1 case 1 / iq1 default:
z7c.o(ttfVar.a(), 1);              // noteId: uuid→16B blob
z7c.o(ree.b(uq9Var), 2);           // ★ op 完整 FlatBuffer 字节
z7c.l(3, uploadImmediately?1:0);
z7c.l(4, hasTitle?1:0);
h0(5,title)/r(5);
z7c.l(6, gk4.v(opId));             // opId: qo5→long 打包
z7c.l(7, clientTime);
```

**op 落库 = `ree.b(uq9)` 整信封字节存 `op` blob 列**——
本地持久层与线型同一字节格式（无二次编码）。

## 3. `gk4.v(qo5)` = ID 打包

```java
((timestamp & 0xFFFFFFFF) << 32) | (site & 0xFFFF)
// ts 高 32 位 + site 低 16 位 → 单列 long 可索引
```

## 4. Room schema（wp1 绑定语句实证）

| 表 | 列 |
|----|-----|
| `ClientNoteUpdate` | id,type,createdAt,favorite,lastOpened,deletedAt,folderId,idempotencyKey |
| `ClientOp` | noteId,op,uploadImmediately,hasTitle,title,opId,clientTime |
| `NoteAsset` | assetHash,status,noteIds,fileSize |
| `PermanentlyDeletedNote` | noteId |
| `SyncedFolderMetadata` | id,parentId,updatedAt,title,color,siblingOrder,emoji |
| `SyncedNoteMetadata` | id,title,createdAt,updatedAt,favorite,lastOpened,deletedAt,folderId,titleOpId,thumbnailUrl,thumbnailOpId,legacyNoteId,mostRecentOpTime,shared,hasRecordings,linkAccessLevel,linkPermissionScope,userAccessLevel（18 列） |
| `SyncedOpMetadata` | id,legacyId,editorSiteId,editorId,createdAt,creatorId,updatedAt,maxServerTime,title,titleOpId,opCount,opFileSize,maxTimestamp,schemaVersion,fingerprintFileLengths,opsChecksum,offsetsChecksum（17 列） |

`SyncedOpMetadata` 的 `opFileSize/opsChecksum/offsetsChecksum/
fingerprintFileLengths` = ops 文件完整性校验指纹列。

## 5. Harmony 对齐

Harmony 本地存储用 Preferences/RDB——等价语义：
op 字节原样入库（不重编码）、qo5→long 打包键。

## 6. 验证

`d02-sqlite-persistence.mjs` 静态断言。

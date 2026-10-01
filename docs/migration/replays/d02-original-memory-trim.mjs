// Phase 1435 replay: 原版内存压力缓存裁剪管线（NbApplication.onTrimMemory/
// onLowMemory → g1a.b(f1a) → 三枚 ehc trimmable 全清）对齐。
// 原版证据：g1a（MemoryTrimmable 注册表+失败隔离）、f1a（BACKGROUNDED/
// CRITICAL）、h1a（接口）、ehc（ehc(0)=hhc.b.clear() 资源解码缓存 /
// ehc(1)=dpc.e.i(-1) 图片 LRU / ehc(2)=ctc.q 铅笔 splat 池）、
// NbApplication onTrimMemory i>=20→BACKGROUNDED / i>=40 与 onLowMemory→
// CRITICAL（i<20 RUNNING_* 前台压力不裁剪）。
// Harmony：MemoryTrimRegistry（注册+失败隔离分发）+ NoteAbility
// onMemoryLevel（MODERATE 不裁剪=原版 i<20、LOW→BACKGROUNDED、
// CRITICAL→CRITICAL）+ 三枚 trimmable：library-thumbnail-bitmaps
// （thumbMap）、editor-image-assets（imageAssets）、editor-pencil-splats
// （shapeRenderer.pencilCache，=ctc.q 等价）。
// 同轴裁定：BackgroundMaintenanceWorker/cs0 = SYNC 域预算化周期维护
// （ForegroundReturned 前台返回即取消）——后端/同步边界 fail-closed。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');

// (1) 注册表本体：f1a 两级 + g1a 语义（注册/注销/失败隔离分发）
const registry = read('note/src/main/ets/data/MemoryTrimRegistry.ets');
assert.match(registry, /enum MemoryTrimLevel/, 'f1a 级别枚举');
assert.match(registry, /BACKGROUNDED[\s\S]{0,80}CRITICAL/, 'BACKGROUNDED+CRITICAL 两级');
assert.match(registry, /registerMemoryTrimmable/, 'g1a.a 登记');
assert.match(registry, /unregisterMemoryTrimmable/, '注销');
assert.match(registry, /trimMemoryCaches/, 'g1a.b 分发');
assert.match(registry, /trimmables\.forEach[\s\S]{0,300}catch/, '失败隔离（单点不中断）');

// (2) NoteAbility.onMemoryLevel：MODERATE 不裁剪（原版 i<20）、LOW/CRITICAL 分档
const ability = read('note/src/main/ets/noteability/NoteAbility.ets');
assert.match(ability, /onMemoryLevel/, 'onMemoryLevel 回调');
assert.match(ability, /MEMORY_LEVEL_CRITICAL[\s\S]{0,200}CRITICAL/, 'CRITICAL 档映射');
assert.match(ability, /MEMORY_LEVEL_LOW[\s\S]{0,200}BACKGROUNDED/, 'LOW 档映射');

// (3) LibraryPage：thumbMap trimmable（ehc(0)/hhc.b 等价）+ 生命周期登记/注销
const library = read('note/src/main/ets/ui/library/LibraryPage.ets');
assert.match(library, /library-thumbnail-bitmaps/, 'thumbnail trimmable 名');
assert.match(library, /trimThumbnailCacheForMemoryPressure/, 'trim 方法');
assert.match(library, /releaseThumbnails\(this\.thumbMap\)[\s\S]{0,300}refreshThumbnails/, '全清+活动页重建');

// (4) NoteCanvasView：imageAssets + pencilCache 两枚 trimmable
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
assert.match(canvas, /editor-image-assets/, 'image-assets trimmable');
assert.match(canvas, /editor-pencil-splats/, 'pencil-splats trimmable');
assert.match(canvas, /trimImageAssetsForMemoryPressure[\s\S]{0,400}refreshImageAssets/, '图片缓存清+重载');
assert.match(canvas, /clearPencilCache/, 'pencil splat 池清');

// (5) 文档登记
const adr = read('docs/migration/adr/ADR-1370-memory-trim-parity.md');
assert.match(adr, /g1a|onTrimMemory/, 'ADR 覆盖注册表管线');
assert.match(adr, /ehc|ctc/, 'ADR 覆盖三 trimmable');
assert.match(adr, /BackgroundMaintenanceWorker|cs0/, 'ADR 覆盖后台维护 fail-closed');

console.log('d02-original-memory-trim: OK (17 checks)');

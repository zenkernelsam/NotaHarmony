// Phase 1453 — 1.4.2 guf.e/twm.d 旋转柄 90° 角度吸附。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   guf.java:29-36 — m=fq9.z(5.0f)=5° 弧度阈值；
//     n=y2(-V,-V/2,0,V/2,V)，V=si5.a.getValue()=π → {-π,-π/2,0,π/2,π}。
//   guf.java:48-64 — e(j, vtf)：atan2(pointer−vtf.d=centerAbsolute) →
//     遍历 n 找 |差|<m 的吸附角 → 减 vtf.i()=e=startingRadians。
//   twm.java:68-72 — d(f,m)：F=round(f/(π/2))·(π/2)，|f−F|≤m → F。
//   vtf.java toString — Rotate(stateId, originalPositions,
//     dragStartPoint=c, centerAbsolute=d, startingRadians=e, …)。
//   ms1.java:525 — vtf 构造：startingRadians=fFloatValue2(+si5.a 若 yj8.G
//     =左柄/RTL 侧 +π 起始补偿)。
//   guf.java:v — 双指捏合会话同用 twm.d(f2, m) 吸附旋转增量。
// Harmony：applySelectionResize 旋转柄支——绝对指针角吸附最近 90° 倍数
//   （5° 阈值），再减起始角；角柄支维持 1.0.3 自由变换语义（登记差异）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 阈值常量 ---
check(canvas.includes('SELECTION_ROTATE_SNAP_RAD: number = Math.PI * 5.0 / 180.0'),
  'snap threshold = fq9.z(5f) = 5° in radians');
check(canvas.includes('guf.e') && canvas.includes('twm.d'),
  'snap constant documented with guf.e/twm.d evidence');

// --- 吸附位置：绝对角先吸附，再减起始角 ---
const apply = canvas.slice(canvas.indexOf('private applySelectionResize('),
  canvas.indexOf('private selectionBoundsCanvas('));
check(apply.includes('this.resizeIsRotate'),
  'snap branch gated on the rotate-handle session (vtf)');
check(apply.includes('Math.round(curRadians / (Math.PI / 2)) * (Math.PI / 2)'),
  'snap target = nearest π/2 multiple (twm.d round semantics)');
check(apply.includes('Math.abs(curRadians - snappedQuarter) <= SELECTION_ROTATE_SNAP_RAD'),
  'snap applies only within 5° of the target angle');
check(apply.indexOf('Math.round(curRadians') <
  apply.indexOf('const radians: number = curRadians'),
  'snap runs on the absolute angle before subtracting startingRadians');
check(apply.includes('curRadians - Math.atan2(startDy, startDx)'),
  'rotation delta = snapped absolute angle − startingRadians (vtf.e)');

// --- 角柄支=wtf 纯缩放会话（P1455 已分离——无角度字段不产旋转） ---
check(apply.includes('wtf(Scale)') && apply.includes('resizeSelectedAxes'),
  'corner drag = wtf two-axis scale session (no rotation field)');

// --- 可执行数学模型：guf.e/twm.d 行为等价验证 ---
const snap = (rad) => {
  const q = Math.round(rad / (Math.PI / 2)) * (Math.PI / 2);
  return Math.abs(rad - q) <= Math.PI * 5.0 / 180.0 ? q : rad;
};
const deg = (d) => d * Math.PI / 180;
check(Math.abs(snap(deg(88)) - Math.PI / 2) < 1e-9,
  'model: 88° snaps to 90°');
check(Math.abs(snap(deg(2)) - 0) < 1e-9,
  'model: 2° snaps to 0°');
check(Math.abs(snap(deg(-176)) - (-Math.PI)) < 1e-9 &&
  Math.abs(snap(deg(176)) - Math.PI) < 1e-9,
  'model: ±176° snaps to ±180° (n covers both edges)');
check(Math.abs(snap(deg(40)) - deg(40)) < 1e-9 &&
  Math.abs(snap(deg(50)) - deg(50)) < 1e-9,
  'model: 40°/50° beyond threshold stay free');
check(Math.abs(snap(deg(86)) - Math.PI / 2) < 1e-9 &&
  Math.abs(snap(deg(84)) - deg(84)) < 1e-9,
  'model: threshold boundary at exactly 5°');

console.log(`D02_ORIGINAL_ROTATE_SNAP_OK TOTAL=${n} FAILED=0`);

import assert from 'node:assert/strict';
import fs from 'node:fs';

const MULTIPLIER = 1118393071;
const MODULUS = 1946926193;
const FALLBACK_SEED = 1544949492;

function nextSeed(seed) {
  return Number((BigInt(seed) * BigInt(MULTIPLIER)) % BigInt(MODULUS));
}

function splatsForStraightPath({ seed, referenceX = 0, width = 4, force = 0.8,
  altitude = 0.2, azimuthX = 0, azimuthY = 1, endX = 30 }) {
  let currentSeed = Math.abs(Math.trunc(seed));
  const pressureScale = Math.min(force, 2) / 2 * 0.97 + 0.03;
  const angleDiff = Math.max(Math.PI / 5 - altitude, 0);
  const count = Math.min(Math.floor(angleDiff / (Math.PI / 125)) + 1, 26);
  const subdivisions = Math.floor(angleDiff / (Math.PI / 125));
  const ellipseRadius = 1.2 * (width / 2) * 0.5 * subdivisions;
  const ellipseScale = angleDiff / (Math.PI / 2) * -0.48 + 0.5;
  const pressureSize = 1 - (1 - Math.min(force, 2) / 2) ** 5;
  const tiltSize = 1 - Math.min((altitude - Math.PI / 2) / -0.9424777960769379, 1) ** 5;
  const sizeFactor = pressureSize * tiltSize + (1 - tiltSize);
  const scale = ellipseScale * width * (sizeFactor * 0.5 + 0.5);
  const angleNorm = Math.min(Math.max(angleDiff / 0.45331853071795863, 0), 1);
  const edgeFactor = (1 - angleNorm) + 0.1 * angleNorm;
  const results = [];
  let xOnPath = referenceX + width * 0.25;
  while (xOnPath <= endX) {
    for (let index = 0; index < count; index++) {
      currentSeed = nextSeed(currentSeed); const u = currentSeed / MODULUS;
      currentSeed = nextSeed(currentSeed); const theta = currentSeed / MODULUS * Math.PI * 2;
      const radius = Math.sqrt(u);
      const across = 0.9 * Math.cos(theta) * radius;
      const along = angleNorm + Math.sin(theta) * radius;
      currentSeed = nextSeed(currentSeed); const rotation = currentSeed / MODULUS * Math.PI * 2;
      results.push({
        x: xOnPath + (along * azimuthX - across * azimuthY) * ellipseRadius,
        y: (along * azimuthY + across * azimuthX) * ellipseRadius,
        rotation,
        scale,
        opacity: (count === 1 ? 1 : 1 - radius) * edgeFactor * pressureScale,
      });
    }
    xOnPath += width * 0.25 * (sizeFactor * 0.5 + 0.5);
  }
  return results;
}

const fallback = splatsForStraightPath({ seed: FALLBACK_SEED });
const negative = splatsForStraightPath({ seed: -12345, referenceX: 10 });
const positive = splatsForStraightPath({ seed: 12345, referenceX: 10 });
const beforeAppend = splatsForStraightPath({ seed: -12345, referenceX: 10, endX: 20 });
assert.deepEqual(negative, positive);
assert.deepEqual(negative.slice(0, beforeAppend.length), beforeAppend);
assert(negative.length > beforeAppend.length);
assert(fallback.length > 0 && negative.length > 0);
assert.equal(fallback.length, 540);
assert.equal(negative.length, 360);
assert.deepEqual(fallback[0], {
  x: -1.677939542976473, y: 16.622045172251802,
  rotation: 6.051765970927006, scale: 1.4764619925891513,
  opacity: 0.05032453478100679,
});
assert.deepEqual(negative[0], {
  x: -1.4522656542599819, y: 17.59178049583085,
  rotation: 0.02337137604544309, scale: 1.4764619925891513,
  opacity: 0.01981311951082389,
});

const persisted = JSON.stringify({
  renderSpec: { isPencil: true, brushWidth: 4 },
  styleMap: [{ backingPencilSeed: -12345,
    backingPencilReferencePoint: { x: 10, y: 0 }, backingDashPhase: 0, backingDashPeriod: 0 }],
  splatPoints: negative,
  bounds: { left: -22.72, top: -22.72, right: 52.72, bottom: 22.72 },
});
const restarted = JSON.parse(persisted);
assert.deepEqual(restarted.splatPoints, negative);
assert.equal(restarted.renderSpec.isPencil, true);
assert.equal(restarted.styleMap[0].backingPencilSeed, -12345);
assert.deepEqual(restarted.bounds,
  { left: -22.72, top: -22.72, right: 52.72, bottom: 22.72 });

const createSource = fs.readFileSync(
  new URL('../../../note/src/main/ets/data/OriginalCreateInkOperation.ets', import.meta.url), 'utf8');
const generatorSource = fs.readFileSync(
  new URL('../../../note/src/main/ets/core/algorithm/PencilSplatGenerator.ets', import.meta.url), 'utf8');
const addSource = fs.readFileSync(
  new URL('../../../note/src/main/ets/data/OriginalAddPathElementsOperation.ets', import.meta.url), 'utf8');
assert.doesNotMatch(createSource, /CREATE_INK_PENCIL_SPLATS_UNSUPPORTED/);
assert.match(createSource, /styleEntry\.backingPencilSeed/);
assert.match(createSource, /backingPencilReferencePoint/);
assert.match(createSource, /isPencil: isPencil/);
assert.match(createSource, /isPencil \? 2\.84 : 1/);
assert.match(createSource, /CREATE_INK_PENCIL_SPLAT_BUDGET_EXCEEDED/);
assert.match(createSource, /maximumSplatCount: MAX_SYNCED_PENCIL_SPLATS/);
assert.match(generatorSource, /Math\.abs\(Math\.trunc\(seed\)\)/);
assert.match(generatorSource, /referencePoint === undefined \? segments\[0\]\.p0 : referencePoint/);
assert.doesNotMatch(addSource, /ADD_PATH_ELEMENTS_PENCIL_UNSUPPORTED/);
assert.match(addSource, /splatPoints: rebuilt\.splatPoints/);
assert.match(addSource, /splatGenerator\.generate\(cubicSegments, pathPoints/);
assert.match(addSource, /stroke\.renderSpec\.isPencil \? 2\.84 : 1/);
assert.match(addSource, /ADD_PATH_ELEMENTS_PENCIL_SPLAT_BUDGET_EXCEEDED/);

console.log(JSON.stringify({ fallbackCount: fallback.length, firstFallback: fallback[0],
  referenceCount: negative.length, firstReference: negative[0] }));

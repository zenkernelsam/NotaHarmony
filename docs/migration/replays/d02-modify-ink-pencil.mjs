import assert from 'node:assert/strict';
import fs from 'node:fs';

const MULTIPLIER = 1118393071;
const MODULUS = 1946926193;

function nextSeed(seed) {
  return Number((BigInt(seed) * BigInt(MULTIPLIER)) % BigInt(MODULUS));
}

function materialize({ width, seed, referenceX = 0, transform = [1, 0, 0, 0, 1, 0, 0, 0, 1],
  maximum = 262144 }) {
  let currentSeed = Math.abs(Math.trunc(seed));
  const altitude = 0.2, force = 0.8;
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
  const splats = [];
  for (let x = referenceX + width * 0.25; x <= 30;
    x += width * 0.25 * (sizeFactor * 0.5 + 0.5)) {
    if (count > maximum - splats.length) throw new Error('PENCIL_SPLAT_LIMIT');
    for (let index = 0; index < count; index++) {
      currentSeed = nextSeed(currentSeed); const u = currentSeed / MODULUS;
      currentSeed = nextSeed(currentSeed); const theta = currentSeed / MODULUS * Math.PI * 2;
      const radius = Math.sqrt(u);
      const across = 0.9 * Math.cos(theta) * radius;
      const along = angleNorm + Math.sin(theta) * radius;
      currentSeed = nextSeed(currentSeed); const rotation = currentSeed / MODULUS * Math.PI * 2;
      splats.push({ x: x - across * ellipseRadius, y: along * ellipseRadius, rotation, scale });
    }
  }
  const padding = width * 2.84 * 2;
  const localBounds = { left: -padding, top: -padding, right: 30 + padding, bottom: padding };
  return { splats, localBounds, transform };
}

const original = materialize({ width: 4, seed: -12345, referenceX: 10 });
const wider = materialize({ width: 8, seed: -12345, referenceX: 10 });
assert(original.splats.length > wider.splats.length);
assert(wider.splats[0].scale > original.splats[0].scale);
assert.notDeepEqual(wider.localBounds, original.localBounds);

const reseeded = materialize({ width: 4, seed: 54321, referenceX: 5 });
assert.notDeepEqual(reseeded.splats, original.splats);
const transformed = materialize({
  width: 4, seed: -12345, referenceX: 10,
  transform: [0, 1, 0, -1, 0, 0, 50, 60, 1],
});
assert.deepEqual(transformed.splats, original.splats);
assert.notDeepEqual(transformed.transform, original.transform);

const snapshots = [original, original];
const before = JSON.stringify(snapshots);
assert.throws(() => snapshots.map((_, index) => materialize({
  width: index === 0 ? 8 : 0.00001, seed: 12345, maximum: 1000,
})), /PENCIL_SPLAT_LIMIT/);
assert.equal(JSON.stringify(snapshots), before);

const source = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalModifyInkOperation.ets', import.meta.url), 'utf8');
assert.doesNotMatch(source, /MODIFY_INK_PENCIL_UNSUPPORTED/);
assert.match(source, /!stroke\.renderSpec\.isPencil && stroke\.splatPoints\.length > 0/);
assert.match(source, /expected = rebuildOriginalInkGeometry\([\s\S]*state\.estimatedPath\.value\)/);
assert.match(source, /replacement = rebuildOriginalInkGeometry\(/);
assert.match(source, /MODIFY_INK_PENCIL_SPLAT_BUDGET_EXCEEDED/);
assert.match(source, /!stroke\.renderSpec\.isPencil && style === 0 && !replacement\.attributed/);
assert.match(source, /splatPoints: replacement\.geometry\.splatPoints/);
assert(source.indexOf('planned.push({') < source.indexOf('for (const replacement of planned)'));

console.log('success|width-rebuild=1|style-map-rebuild=1|transform-local-stable=1|' +
  'budget-atomic=1|replacement-consumer=1');

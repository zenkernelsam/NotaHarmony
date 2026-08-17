import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const normalize = value => value.replaceAll('\r\n', '\n');
const readRepo = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const readOriginal = name => normalize(fs.readFileSync(path.join(originalRoot, name), 'utf8'));

const z8a = readOriginal('z8a.java');
const jqi = readOriginal('jqi.java');
const fa2 = readOriginal('fa2.java');
const ed0 = readOriginal('ed0.java');
const production = readRepo('note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets');
const fixture = readRepo('note/src/test/WidthOutlineBuilder.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

let total = 0;
let failed = 0;

function check(name, condition) {
  total++;
  if (!condition) {
    failed++;
    console.error(`FAIL: ${name}`);
    return;
  }
  console.log(`PASS: ${name}`);
}

function buildProfile(widths, componentLengths) {
  const lengths = componentLengths.map(length => Math.max(length, 0.000001));
  const slopes = lengths.map((length, index) =>
    (widths[index + 1] - widths[index]) / length);
  const derivatives = new Array(widths.length);
  derivatives[0] = slopes[0];
  derivatives[derivatives.length - 1] = slopes[slopes.length - 1];
  for (let index = 1; index < widths.length - 1; index++) {
    const previousSlope = slopes[index - 1];
    const nextSlope = slopes[index];
    if (previousSlope * nextSlope <= 0) {
      derivatives[index] = 0;
      continue;
    }
    const previousLength = lengths[index - 1];
    const nextLength = lengths[index];
    derivatives[index] = 3 * (previousLength + nextLength) /
      (((2 * previousLength + nextLength) / nextSlope) +
        ((2 * nextLength + previousLength) / previousSlope));
  }
  return { widths, lengths, derivatives };
}

function hermite(profile, componentIndex, t) {
  const t2 = t * t;
  const t3 = t2 * t;
  const startWidth = profile.widths[componentIndex];
  const endWidth = profile.widths[componentIndex + 1];
  const startDerivative = profile.derivatives[componentIndex];
  const endDerivative = profile.derivatives[componentIndex + 1];
  const length = profile.lengths[componentIndex];
  return (t3 - t2) * endDerivative * length +
    ((-2 * t3) + 3 * t2) * endWidth +
    (t3 - 2 * t2 + t) * startDerivative * length +
    (2 * t3 - 3 * t2 + 1) * startWidth;
}

function subdivisionCount(profile, componentIndex) {
  const startWidth = profile.widths[componentIndex];
  const endWidth = profile.widths[componentIndex + 1];
  let maximumDeviation = 0;
  for (const probe of [0.25, 0.5, 0.75]) {
    const linear = startWidth + (endWidth - startWidth) * probe;
    maximumDeviation = Math.max(maximumDeviation,
      Math.abs(hermite(profile, componentIndex, probe) - linear));
  }
  const scaledDeviation = maximumDeviation * 1.2;
  const tolerance = Math.max(startWidth, endWidth, 0.05) * 0.005;
  if (scaledDeviation <= tolerance) return 1;
  return Math.max(2, Math.min(6, Math.ceil(Math.sqrt(scaledDeviation / tolerance))));
}

const turningProfile = buildProfile([1, 3, 2], [10, 10]);
const risingProfile = buildProfile([1, 2, 6], [10, 20]);

check('original clamps component chord length to 1e-6 before width slopes',
  z8a.includes('if (dL0 < 1.0E-6d)') && z8a.includes('dL0 = 1.0E-6d;'));
check('original computes one secant width slope per attributed path component',
  z8a.includes('dArr3[i19] = (dArr2[i20] - dArr2[i19]) / dArr[i19];'));
check('original endpoint derivatives equal the first and last secant slopes',
  z8a.includes('dArr4[i17] = dArr3[i17];') &&
    z8a.includes('dArr4[i7] = dArr3[i7 - 1];'));
check('original zeros an interior derivative when adjacent slopes change sign',
  z8a.includes('if (d10 * d11 <= 0.0d)') && z8a.includes('dC = 0.0d;'));
check('original otherwise uses the chord-length weighted harmonic derivative',
  z8a.includes('dC = (3.0d * (d12 + d13)) /') &&
    fa2.includes('return ((d * d2) + d3) / d4;'));
check('original probes Hermite deviation at quarter half and three-quarter positions',
  jqi.includes('public static final double[] a = {0.25d, 0.5d, 0.75d};') &&
    z8a.includes('double d19 = jqi.a[i31];'));
check('original Hermite evaluator scales endpoint derivatives by component length',
  jqi.includes('((d8 - d7) * d5 * d3)') &&
    jqi.includes('((d8 - (2.0d * d7)) + d6) * d2 * d3'));
check('original width deviation uses 1.2 safety and 0.5 percent relative tolerance',
  z8a.includes('double d23 = dMax * 1.2d;') &&
    z8a.includes('Math.max(Math.max(d15, d22), 0.05d) * 0.005d'));
check('original adaptive component count is sqrt-based and clamped to 2 through 6',
  z8a.includes('Math.ceil(Math.sqrt(d23 / dMax2))') &&
    z8a.includes(', 2, 6)'));
check('original slices the source curve at equal component parameter fractions',
  z8a.includes('double d25 = ((double) i38) / d24;') &&
    z8a.includes('double d26 = ((double) i41) / d24;') &&
    z8a.includes('.b(d25, d26).a();'));
check('original publishes an interpolated stroke width at every inserted boundary',
  z8a.includes('double d29 = jqi.d(d15, d17, d14, d27, d18, d28);') &&
    z8a.includes('ed0Var = new ed0(d29, d31, dA2, dB2, dC3);') &&
    ed0.includes('return this.I;'));

check('turning width slopes produce the original zero derivative at the local maximum',
  turningProfile.derivatives[0] === 0.2 && turningProfile.derivatives[1] === 0 &&
    turningProfile.derivatives[2] === -0.1);
check('same-sign unequal slopes use the original weighted harmonic derivative',
  Math.abs(risingProfile.derivatives[1] - 0.12857142857142856) < 1e-15);
check('original numeric refinement chooses five then four pieces for widths 1 3 2',
  subdivisionCount(turningProfile, 0) === 5 && subdivisionCount(turningProfile, 1) === 4);
check('original numeric Hermite samples retain the pressure peak instead of linear taper',
  Math.abs(hermite(turningProfile, 0, 0.4) - 1.992) < 1e-12 &&
    Math.abs(hermite(turningProfile, 1, 0.5) - 2.625) < 1e-12);
check('original monotone profile stays inside adjacent endpoint extrema',
  Array.from({ length: 101 }, (_, index) => index / 100).every(t => {
    const first = hermite(turningProfile, 0, t);
    const second = hermite(turningProfile, 1, t);
    return first >= 1 && first <= 3 && second >= 2 && second <= 3;
  }));

check('Harmony declares the original probes tolerances and 2 through 6 clamp',
  production.includes('ORIGINAL_WIDTH_PROBES: number[] = [0.25, 0.5, 0.75]') &&
    production.includes('ORIGINAL_WIDTH_DEVIATION_SCALE: number = 1.2') &&
    production.includes('ORIGINAL_WIDTH_RELATIVE_TOLERANCE: number = 0.005') &&
    production.includes('ORIGINAL_WIDTH_MIN_SUBDIVISIONS: number = 2') &&
    production.includes('ORIGINAL_WIDTH_MAX_SUBDIVISIONS: number = 6'));
check('Harmony builds chord-length secants and sign-preserving interior derivatives',
  production.includes('(widths[i + 1] - widths[i]) / componentLengths[i]') &&
    production.includes('if (previousSlope * nextSlope <= 0)') &&
    production.includes('derivatives[i] = 3 * (previousLength + nextLength) /'));
check('Harmony evaluates the same component-length-scaled Hermite basis',
  production.includes('(t3 - t2) * endDerivative * length') &&
    production.includes('(t3 - 2 * t2 + t) * startDerivative * length'));
check('Harmony measures quarter-point deviation and applies the original subdivision formula',
  production.includes('for (const probe of WidthOutlineBuilder.ORIGINAL_WIDTH_PROBES)') &&
    production.includes('Math.ceil(Math.sqrt(scaledDeviation / tolerance))'));
check('Harmony slices each fitted cubic before geometry flattening',
  production.includes('const sliced: CubicSegment = this.sliceCubic(segment, startT, endT);') &&
    production.includes('this.flattenCubic(sliced, startWidth, endWidth, baseWidth, 0, samples);'));
check('Harmony keeps single-component constant-width and corrupt-cubic fallbacks explicit',
  production.includes('if (segments.length < 2 || anchors.length !== segments.length)') &&
    production.includes('if (!widthChanges)') && production.includes('return this.samplesFromPolyline(centerline);'));
check('ArkTS fixture locks the original 1.992 and 2.625 Hermite samples',
  fixture.includes('contains(result.outlinePoints, 4, 1.992') &&
    fixture.includes('contains(result.outlinePoints, 15, 2.625'));
check('ArkTS fixture covers monotone extrema and constant-width non-refinement',
  fixture.includes('inside adjacent width extrema') &&
    fixture.includes('does not subdivide constant width components'));
check('WidthOutlineBuilder fixture remains registered in the executed suite',
  fixtureList.includes("import widthOutlineBuilderTest from './WidthOutlineBuilder.test';") &&
    fixtureList.includes('widthOutlineBuilderTest();'));

if (failed > 0) {
  console.error(`D02_ORIGINAL_VARIABLE_WIDTH_HERMITE_PROFILE_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_ORIGINAL_VARIABLE_WIDTH_HERMITE_PROFILE_OK TOTAL=${total} FAILED=0`);

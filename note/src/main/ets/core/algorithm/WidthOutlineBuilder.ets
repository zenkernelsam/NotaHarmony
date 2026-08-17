// Variable-width outline geometry for the original bezierkit attributed path.
// Width interpolation follows the original attributed-component algorithm; the final
// offset/join polygon remains the documented Harmony approximation.
// This pure geometry module intentionally has no HarmonyOS platform dependencies.
import { CubicSegment, Point2D } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface OutlineResult {
  outlinePoints: Point2D[];
  isValid: boolean;
}

interface OutlineSample {
  position: Point2D;
  widthFactor: number;
}

interface CubicPair {
  left: CubicSegment;
  right: CubicSegment;
}

interface CubicWidthAnchor {
  startWidth: number;
  endWidth: number;
}

interface OriginalWidthProfile {
  componentLengths: number[];
  widths: number[];
  derivatives: number[];
  subdivisions: number[];
}

export class WidthOutlineBuilder {
  // Port tolerances for the documented adaptive approximation; bezierkit does not expose equivalents.
  private static readonly MIN_SEGMENT_LENGTH: number = 0.0001;
  private static readonly CURVE_FLATNESS_TOLERANCE: number = 0.2;
  private static readonly ARC_TOLERANCE: number = 0.15;
  private static readonly MAX_SUBDIVISION_DEPTH: number = 10;
  private static readonly MITER_LIMIT: number = 4;
  private static readonly CIRCLE_SEGMENTS: number = 16;
  private static readonly ORIGINAL_WIDTH_MIN_COMPONENT_LENGTH: number = 0.000001;
  private static readonly ORIGINAL_WIDTH_DEVIATION_SCALE: number = 1.2;
  private static readonly ORIGINAL_WIDTH_RELATIVE_TOLERANCE: number = 0.005;
  private static readonly ORIGINAL_WIDTH_MIN_REFERENCE: number = 0.05;
  private static readonly ORIGINAL_WIDTH_MIN_SUBDIVISIONS: number = 2;
  private static readonly ORIGINAL_WIDTH_MAX_SUBDIVISIONS: number = 6;
  private static readonly ORIGINAL_WIDTH_PROBES: number[] = [0.25, 0.5, 0.75];

  build(centerline: StrokePathPoint[], baseWidth: number,
    cubicSegments?: CubicSegment[]): OutlineResult {
    if (centerline.length === 0 || !Number.isFinite(baseWidth) || baseWidth <= 0) {
      return { outlinePoints: [], isValid: false };
    }
    const samples: OutlineSample[] = cubicSegments !== undefined && cubicSegments.length > 0 ?
      this.flattenCubics(centerline, cubicSegments, baseWidth) :
      this.samplesFromPolyline(centerline);
    const cleaned: OutlineSample[] = this.removeDegenerateSamples(samples);
    if (cleaned.length === 0) {
      return { outlinePoints: [], isValid: false };
    }
    if (cleaned.length === 1) {
      return this.buildDegenerateCircle(cleaned[0].position,
        cleaned[0].widthFactor * baseWidth / 2);
    }

    const tangents: Point2D[] = this.computeSegmentTangents(cleaned);
    if (tangents.length === 0) {
      return this.buildDegenerateCircle(cleaned[0].position,
        cleaned[0].widthFactor * baseWidth / 2);
    }
    const left: Point2D[] = this.buildSide(cleaned, tangents, baseWidth, 1);
    const right: Point2D[] = this.buildSide(cleaned, tangents, baseWidth, -1);
    if (left.length === 0 || right.length === 0) {
      return { outlinePoints: [], isValid: false };
    }

    const outline: Point2D[] = [];
    const startRadius: number = this.halfWidth(cleaned[0].widthFactor, baseWidth);
    const endIndex: number = cleaned.length - 1;
    const endRadius: number = this.halfWidth(cleaned[endIndex].widthFactor, baseWidth);
    const startNormal: Point2D = this.leftNormal(tangents[0]);
    const endNormal: Point2D = this.leftNormal(tangents[tangents.length - 1]);
    this.appendArc(outline, cleaned[0].position, startRadius,
      Math.atan2(-startNormal.y, -startNormal.x), Math.atan2(startNormal.y, startNormal.x), -1);
    this.appendPoints(outline, left);
    this.appendArc(outline, cleaned[endIndex].position, endRadius,
      Math.atan2(endNormal.y, endNormal.x), Math.atan2(-endNormal.y, -endNormal.x), -1);
    for (let i: number = right.length - 1; i >= 0; i--) {
      this.appendUnique(outline, right[i]);
    }
    return { outlinePoints: outline, isValid: outline.length >= 3 };
  }

  private flattenCubics(centerline: StrokePathPoint[], segments: CubicSegment[],
    baseWidth: number): OutlineSample[] {
    const anchors: CubicWidthAnchor[] | null = this.resolveCubicWidthAnchors(centerline, segments);
    if (anchors === null) {
      return this.samplesFromPolyline(centerline);
    }
    const widthProfile: OriginalWidthProfile | null = this.buildOriginalWidthProfile(segments, anchors);
    const samples: OutlineSample[] = [];
    for (let i: number = 0; i < segments.length; i++) {
      const segment: CubicSegment = segments[i];
      const anchor: CubicWidthAnchor = anchors[i];
      if (samples.length === 0) {
        samples.push({ position: segment.p0, widthFactor: anchor.startWidth });
      } else if (this.distanceSquared(samples[samples.length - 1].position, segment.p0) > 1e-12) {
        samples.push({ position: segment.p0, widthFactor: anchor.startWidth });
      }
      if (widthProfile === null) {
        this.flattenCubic(segment, anchor.startWidth, anchor.endWidth, baseWidth, 0, samples);
        continue;
      }
      const subdivisions: number = widthProfile.subdivisions[i];
      if (subdivisions === 1) {
        this.flattenCubic(segment, anchor.startWidth, anchor.endWidth, baseWidth, 0, samples);
        continue;
      }
      for (let partIndex: number = 0; partIndex < subdivisions; partIndex++) {
        const startT: number = partIndex / subdivisions;
        const endT: number = (partIndex + 1) / subdivisions;
        const sliced: CubicSegment = this.sliceCubic(segment, startT, endT);
        const startWidth: number = this.originalHermiteWidth(widthProfile, i, startT);
        const endWidth: number = this.originalHermiteWidth(widthProfile, i, endT);
        this.flattenCubic(sliced, startWidth, endWidth, baseWidth, 0, samples);
      }
    }
    return samples;
  }

  private resolveCubicWidthAnchors(centerline: StrokePathPoint[],
    segments: CubicSegment[]): CubicWidthAnchor[] | null {
    const anchors: CubicWidthAnchor[] = [];
    let sourceCursor: number = 0;
    for (let i: number = 0; i < segments.length; i++) {
      const segment: CubicSegment = segments[i];
      if (!this.isFiniteCubic(segment)) {
        return null;
      }
      let startIndex: number = sourceCursor;
      if (i === 0 || this.distanceSquared(centerline[startIndex].position, segment.p0) > 1e-12) {
        startIndex = this.findClosestSourceIndex(centerline, segment.p0, sourceCursor);
      }
      const minimumEnd: number = Math.min(startIndex + 1, centerline.length - 1);
      const endIndex: number = this.findClosestSourceIndex(centerline, segment.p3, minimumEnd);
      sourceCursor = Math.max(startIndex, endIndex);
      anchors.push({
        startWidth: this.validWidthFactor(centerline[startIndex].widthFactor),
        endWidth: this.validWidthFactor(centerline[endIndex].widthFactor),
      });
    }
    return anchors;
  }

  private buildOriginalWidthProfile(segments: CubicSegment[],
    anchors: CubicWidthAnchor[]): OriginalWidthProfile | null {
    if (segments.length < 2 || anchors.length !== segments.length) {
      return null;
    }
    const widths: number[] = [anchors[0].startWidth];
    const componentLengths: number[] = [];
    let widthChanges: boolean = false;
    for (let i: number = 0; i < segments.length; i++) {
      const width: number = anchors[i].endWidth;
      widths.push(width);
      if (width !== widths[0]) {
        widthChanges = true;
      }
      componentLengths.push(Math.max(
        this.distance(segments[i].p0, segments[i].p3),
        WidthOutlineBuilder.ORIGINAL_WIDTH_MIN_COMPONENT_LENGTH));
    }
    if (!widthChanges) {
      return null;
    }
    const slopes: number[] = [];
    for (let i: number = 0; i < componentLengths.length; i++) {
      slopes.push((widths[i + 1] - widths[i]) / componentLengths[i]);
    }
    const derivatives: number[] = new Array<number>(widths.length);
    derivatives[0] = slopes[0];
    derivatives[derivatives.length - 1] = slopes[slopes.length - 1];
    for (let i: number = 1; i < widths.length - 1; i++) {
      const previousSlope: number = slopes[i - 1];
      const nextSlope: number = slopes[i];
      if (previousSlope * nextSlope <= 0) {
        derivatives[i] = 0;
        continue;
      }
      const previousLength: number = componentLengths[i - 1];
      const nextLength: number = componentLengths[i];
      derivatives[i] = 3 * (previousLength + nextLength) /
        (((2 * previousLength + nextLength) / nextSlope) +
          ((2 * nextLength + previousLength) / previousSlope));
    }
    const subdivisions: number[] = [];
    const profile: OriginalWidthProfile = {
      componentLengths: componentLengths,
      widths: widths,
      derivatives: derivatives,
      subdivisions: subdivisions,
    };
    for (let i: number = 0; i < segments.length; i++) {
      subdivisions.push(this.originalWidthSubdivisionCount(profile, i));
    }
    return profile;
  }

  private originalWidthSubdivisionCount(profile: OriginalWidthProfile,
    componentIndex: number): number {
    const startWidth: number = profile.widths[componentIndex];
    const endWidth: number = profile.widths[componentIndex + 1];
    let maximumDeviation: number = 0;
    for (const probe of WidthOutlineBuilder.ORIGINAL_WIDTH_PROBES) {
      const curved: number = this.originalHermiteWidth(profile, componentIndex, probe);
      const linear: number = startWidth + (endWidth - startWidth) * probe;
      maximumDeviation = Math.max(maximumDeviation, Math.abs(curved - linear));
    }
    const scaledDeviation: number = maximumDeviation *
      WidthOutlineBuilder.ORIGINAL_WIDTH_DEVIATION_SCALE;
    const tolerance: number = Math.max(
      Math.max(startWidth, endWidth), WidthOutlineBuilder.ORIGINAL_WIDTH_MIN_REFERENCE) *
      WidthOutlineBuilder.ORIGINAL_WIDTH_RELATIVE_TOLERANCE;
    // The original skips overflow; valid persisted inputs stay finite. Harmony also treats
    // any derived non-finite value as "no extra width split" instead of emitting NaN geometry.
    if (!Number.isFinite(scaledDeviation) || scaledDeviation <= tolerance) {
      return 1;
    }
    const requested: number = Math.ceil(Math.sqrt(scaledDeviation / tolerance));
    return Math.max(WidthOutlineBuilder.ORIGINAL_WIDTH_MIN_SUBDIVISIONS,
      Math.min(WidthOutlineBuilder.ORIGINAL_WIDTH_MAX_SUBDIVISIONS, requested));
  }

  private originalHermiteWidth(profile: OriginalWidthProfile,
    componentIndex: number, t: number): number {
    const startWidth: number = profile.widths[componentIndex];
    const endWidth: number = profile.widths[componentIndex + 1];
    const startDerivative: number = profile.derivatives[componentIndex];
    const endDerivative: number = profile.derivatives[componentIndex + 1];
    const length: number = profile.componentLengths[componentIndex];
    const t2: number = t * t;
    const t3: number = t2 * t;
    return (t3 - t2) * endDerivative * length +
      ((-2 * t3) + 3 * t2) * endWidth +
      (t3 - 2 * t2 + t) * startDerivative * length +
      (2 * t3 - 3 * t2 + 1) * startWidth;
  }

  private flattenCubic(segment: CubicSegment, startWidth: number, endWidth: number,
    baseWidth: number, depth: number, output: OutlineSample[]): void {
    if (depth >= WidthOutlineBuilder.MAX_SUBDIVISION_DEPTH ||
      this.cubicIsFlatEnough(segment, baseWidth)) {
      output.push({ position: segment.p3, widthFactor: endWidth });
      return;
    }
    const halves: CubicPair = this.splitCubicHalf(segment);
    const middleWidth: number = (startWidth + endWidth) / 2;
    this.flattenCubic(halves.left, startWidth, middleWidth, baseWidth, depth + 1, output);
    this.flattenCubic(halves.right, middleWidth, endWidth, baseWidth, depth + 1, output);
  }

  private cubicIsFlatEnough(segment: CubicSegment, baseWidth: number): boolean {
    const chord: Point2D = this.diff(segment.p3, segment.p0);
    const chordLength: number = this.length(chord);
    if (chordLength < WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
      return this.distance(segment.p0, segment.p1) <= WidthOutlineBuilder.CURVE_FLATNESS_TOLERANCE &&
        this.distance(segment.p0, segment.p2) <= WidthOutlineBuilder.CURVE_FLATNESS_TOLERANCE;
    }
    const flatness: number = Math.max(
      this.pointLineDistance(segment.p1, segment.p0, segment.p3),
      this.pointLineDistance(segment.p2, segment.p0, segment.p3));
    const startTangent: Point2D = this.usableDirection(
      this.diff(segment.p1, segment.p0), chord);
    const endTangent: Point2D = this.usableDirection(
      this.diff(segment.p3, segment.p2), chord);
    const tangentDot: number = this.clamp(this.dot(startTangent, endTangent), -1, 1);
    const tangentAngle: number = Math.acos(tangentDot);
    // Wider outlines amplify tangent error, so their accepted angular step is smaller.
    const maxAngle: number = this.clamp(1 / Math.max(baseWidth, 1), 0.04, 0.3);
    return flatness <= WidthOutlineBuilder.CURVE_FLATNESS_TOLERANCE && tangentAngle <= maxAngle;
  }

  private splitCubicHalf(segment: CubicSegment): CubicPair {
    return this.splitCubic(segment, 0.5);
  }

  private splitCubic(segment: CubicSegment, t: number): CubicPair {
    const p01: Point2D = this.interpolatePoint(segment.p0, segment.p1, t);
    const p12: Point2D = this.interpolatePoint(segment.p1, segment.p2, t);
    const p23: Point2D = this.interpolatePoint(segment.p2, segment.p3, t);
    const p012: Point2D = this.interpolatePoint(p01, p12, t);
    const p123: Point2D = this.interpolatePoint(p12, p23, t);
    const middle: Point2D = this.interpolatePoint(p012, p123, t);
    return {
      left: { p0: segment.p0, p1: p01, p2: p012, p3: middle },
      right: { p0: middle, p1: p123, p2: p23, p3: segment.p3 },
    };
  }

  private sliceCubic(segment: CubicSegment, startT: number, endT: number): CubicSegment {
    if (startT <= 0 && endT >= 1) {
      return segment;
    }
    const throughEnd: CubicSegment = this.splitCubic(segment, endT).left;
    if (startT <= 0) {
      return throughEnd;
    }
    return this.splitCubic(throughEnd, startT / endT).right;
  }

  private samplesFromPolyline(centerline: StrokePathPoint[]): OutlineSample[] {
    const samples: OutlineSample[] = [];
    for (const point of centerline) {
      if (this.isFinitePoint(point.position)) {
        samples.push({
          position: point.position,
          widthFactor: this.validWidthFactor(point.widthFactor),
        });
      }
    }
    return samples;
  }

  private removeDegenerateSamples(samples: OutlineSample[]): OutlineSample[] {
    const result: OutlineSample[] = [];
    for (const sample of samples) {
      if (!this.isFinitePoint(sample.position)) {
        continue;
      }
      if (result.length === 0 || this.distance(result[result.length - 1].position, sample.position) >=
        WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        result.push({ position: sample.position, widthFactor: sample.widthFactor });
      } else {
        // Duplicate samples carry no tangent; retain the larger radius so a pressure peak is not lost.
        result[result.length - 1].widthFactor = Math.max(
          result[result.length - 1].widthFactor, sample.widthFactor);
      }
    }
    return result;
  }

  private computeSegmentTangents(samples: OutlineSample[]): Point2D[] {
    const tangents: Point2D[] = [];
    for (let i: number = 0; i < samples.length - 1; i++) {
      const delta: Point2D = this.diff(samples[i + 1].position, samples[i].position);
      const length: number = this.length(delta);
      if (length >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        tangents.push({ x: delta.x / length, y: delta.y / length });
      }
    }
    return tangents;
  }

  private buildSide(samples: OutlineSample[], tangents: Point2D[], baseWidth: number,
    sideSign: number): Point2D[] {
    const side: Point2D[] = [];
    const firstNormal: Point2D = this.scale(this.leftNormal(tangents[0]), sideSign);
    this.appendUnique(side, this.add(samples[0].position,
      this.scale(firstNormal, this.halfWidth(samples[0].widthFactor, baseWidth))));
    for (let i: number = 1; i < samples.length - 1; i++) {
      const center: Point2D = samples[i].position;
      const radius: number = this.halfWidth(samples[i].widthFactor, baseWidth);
      const previousTangent: Point2D = tangents[i - 1];
      const nextTangent: Point2D = tangents[i];
      const previousNormal: Point2D = this.scale(this.leftNormal(previousTangent), sideSign);
      const nextNormal: Point2D = this.scale(this.leftNormal(nextTangent), sideSign);
      const previousOffset: Point2D = this.add(center, this.scale(previousNormal, radius));
      const nextOffset: Point2D = this.add(center, this.scale(nextNormal, radius));
      const turn: number = this.cross(previousTangent, nextTangent);
      const directionDot: number = this.dot(previousTangent, nextTangent);

      if (Math.abs(turn) < 1e-8 && directionDot > 0) {
        this.appendUnique(side, this.midpoint(previousOffset, nextOffset));
      } else if (directionDot < -0.98) {
        // A cusp has no stable inside intersection. Use opposite semicircles for the two sides.
        this.appendArc(side, center, radius, Math.atan2(previousNormal.y, previousNormal.x),
          Math.atan2(nextNormal.y, nextNormal.x), sideSign > 0 ? -1 : 1);
      } else if (turn * sideSign < 0) {
        // The outside of a turn is a true circular join centered on the centerline vertex.
        this.appendArc(side, center, radius, Math.atan2(previousNormal.y, previousNormal.x),
          Math.atan2(nextNormal.y, nextNormal.x), turn > 0 ? 1 : -1);
      } else {
        const intersection: Point2D | null = this.lineIntersection(
          previousOffset, previousTangent, nextOffset, nextTangent);
        if (intersection !== null &&
          this.distance(intersection, center) <= Math.max(radius, 1e-6) *
            WidthOutlineBuilder.MITER_LIMIT) {
          this.appendUnique(side, intersection);
        } else {
          // Parallel or excessive inside miters fall back to a bounded bevel, never a spike.
          this.appendUnique(side, previousOffset);
          this.appendUnique(side, nextOffset);
        }
      }
    }
    const lastIndex: number = samples.length - 1;
    const lastNormal: Point2D = this.scale(this.leftNormal(tangents[tangents.length - 1]), sideSign);
    this.appendUnique(side, this.add(samples[lastIndex].position,
      this.scale(lastNormal, this.halfWidth(samples[lastIndex].widthFactor, baseWidth))));
    return side;
  }

  private appendArc(output: Point2D[], center: Point2D, radius: number,
    startAngle: number, endAngle: number, direction: number): void {
    if (radius <= 0) {
      this.appendUnique(output, center);
      return;
    }
    let sweep: number = endAngle - startAngle;
    if (direction > 0) {
      while (sweep < 0) {
        sweep += Math.PI * 2;
      }
    } else {
      while (sweep > 0) {
        sweep -= Math.PI * 2;
      }
    }
    const maximumStep: number = this.arcMaximumStep(radius);
    const segmentCount: number = Math.max(1, Math.ceil(Math.abs(sweep) / maximumStep));
    for (let i: number = 0; i <= segmentCount; i++) {
      const angle: number = startAngle + sweep * i / segmentCount;
      this.appendUnique(output, {
        x: center.x + Math.cos(angle) * radius,
        y: center.y + Math.sin(angle) * radius,
      });
    }
  }

  private arcMaximumStep(radius: number): number {
    const cosine: number = this.clamp(1 - WidthOutlineBuilder.ARC_TOLERANCE / radius, -1, 1);
    return this.clamp(2 * Math.acos(cosine), Math.PI / 24, Math.PI / 6);
  }

  private lineIntersection(firstOrigin: Point2D, firstDirection: Point2D,
    secondOrigin: Point2D, secondDirection: Point2D): Point2D | null {
    const denominator: number = this.cross(firstDirection, secondDirection);
    if (Math.abs(denominator) < 1e-8) {
      return null;
    }
    const between: Point2D = this.diff(secondOrigin, firstOrigin);
    const amount: number = this.cross(between, secondDirection) / denominator;
    const result: Point2D = this.add(firstOrigin, this.scale(firstDirection, amount));
    return this.isFinitePoint(result) ? result : null;
  }

  private findClosestSourceIndex(centerline: StrokePathPoint[], target: Point2D,
    minimumIndex: number): number {
    let bestIndex: number = this.clampIndex(minimumIndex, centerline.length);
    let bestDistance: number = Number.POSITIVE_INFINITY;
    for (let i: number = bestIndex; i < centerline.length; i++) {
      const distance: number = this.distanceSquared(centerline[i].position, target);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
      if (distance <= 1e-12) {
        return i;
      }
    }
    return bestIndex;
  }

  private buildDegenerateCircle(center: Point2D, radius: number): OutlineResult {
    if (!Number.isFinite(radius) || radius <= 0) {
      return { outlinePoints: [], isValid: false };
    }
    const outline: Point2D[] = [];
    for (let i: number = 0; i < WidthOutlineBuilder.CIRCLE_SEGMENTS; i++) {
      const angle: number = Math.PI * 2 * i / WidthOutlineBuilder.CIRCLE_SEGMENTS;
      outline.push({
        x: center.x + Math.cos(angle) * radius,
        y: center.y + Math.sin(angle) * radius,
      });
    }
    return { outlinePoints: outline, isValid: true };
  }

  private appendPoints(target: Point2D[], source: Point2D[]): void {
    for (const point of source) {
      this.appendUnique(target, point);
    }
  }

  private appendUnique(points: Point2D[], point: Point2D): void {
    if (points.length === 0 ||
      this.distanceSquared(points[points.length - 1], point) > 1e-16) {
      points.push(point);
    }
  }

  private halfWidth(widthFactor: number, baseWidth: number): number {
    return this.validWidthFactor(widthFactor) * baseWidth / 2;
  }

  private validWidthFactor(widthFactor: number): number {
    return Number.isFinite(widthFactor) ? Math.max(0, widthFactor) : 1;
  }

  private usableDirection(preferred: Point2D, fallback: Point2D): Point2D {
    const preferredLength: number = this.length(preferred);
    if (preferredLength >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
      return this.scale(preferred, 1 / preferredLength);
    }
    const fallbackLength: number = this.length(fallback);
    return fallbackLength >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH ?
      this.scale(fallback, 1 / fallbackLength) : { x: 1, y: 0 };
  }

  private pointLineDistance(point: Point2D, lineStart: Point2D, lineEnd: Point2D): number {
    const line: Point2D = this.diff(lineEnd, lineStart);
    const lineLength: number = this.length(line);
    if (lineLength < WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
      return this.distance(point, lineStart);
    }
    return Math.abs(this.cross(this.diff(point, lineStart), line)) / lineLength;
  }

  private isFiniteCubic(segment: CubicSegment): boolean {
    return this.isFinitePoint(segment.p0) && this.isFinitePoint(segment.p1) &&
      this.isFinitePoint(segment.p2) && this.isFinitePoint(segment.p3);
  }

  private isFinitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private clampIndex(index: number, length: number): number {
    return Math.max(0, Math.min(Math.floor(index), length - 1));
  }

  private clamp(value: number, minimum: number, maximum: number): number {
    return Math.max(minimum, Math.min(maximum, value));
  }

  private leftNormal(tangent: Point2D): Point2D {
    return { x: -tangent.y, y: tangent.x };
  }

  private midpoint(first: Point2D, second: Point2D): Point2D {
    return { x: (first.x + second.x) / 2, y: (first.y + second.y) / 2 };
  }

  private interpolatePoint(first: Point2D, second: Point2D, t: number): Point2D {
    return {
      x: first.x + (second.x - first.x) * t,
      y: first.y + (second.y - first.y) * t,
    };
  }

  private add(first: Point2D, second: Point2D): Point2D {
    return { x: first.x + second.x, y: first.y + second.y };
  }

  private diff(first: Point2D, second: Point2D): Point2D {
    return { x: first.x - second.x, y: first.y - second.y };
  }

  private scale(point: Point2D, amount: number): Point2D {
    return { x: point.x * amount, y: point.y * amount };
  }

  private dot(first: Point2D, second: Point2D): number {
    return first.x * second.x + first.y * second.y;
  }

  private cross(first: Point2D, second: Point2D): number {
    return first.x * second.y - first.y * second.x;
  }

  private length(point: Point2D): number {
    return Math.sqrt(point.x * point.x + point.y * point.y);
  }

  private distance(first: Point2D, second: Point2D): number {
    return this.length(this.diff(first, second));
  }

  private distanceSquared(first: Point2D, second: Point2D): number {
    const dx: number = first.x - second.x;
    const dy: number = first.y - second.y;
    return dx * dx + dy * dy;
  }
}

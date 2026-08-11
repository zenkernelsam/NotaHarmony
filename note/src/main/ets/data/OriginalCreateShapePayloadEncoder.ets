import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead, ShapeElement,
} from '../core/model/ElementTypes';
import { Point2D } from '../core/model/GeometryTypes';
import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';

const ORIGINAL_LINE_DEFINITION: number = 1;
const ORIGINAL_POLYGON_DEFINITION: number = 2;
const ORIGINAL_ELLIPSE_DEFINITION: number = 3;
const MAX_LOCAL_SHAPE_POINTS: number = 100000;

interface OriginalShapePlacement {
  originX: number;
  originY: number;
  rotation: number | null;
}

interface EncodedDefinition {
  type: number;
  table: number;
}

export function encodeOriginalLocalCreateShape(page: OriginalSequenceIdentity,
  shape: ShapeElement, averageForce: number | null): Uint8Array {
  validateOriginalSequenceIdentity(page);
  validateLocalShape(shape, averageForce);
  const placement: OriginalShapePlacement = originalPlacement(shape);
  const builder: ForwardFlatBufferBuilder = new ForwardFlatBufferBuilder(
    256 + (shape.type === ElementType.POLYGON ? shape.vertices.length * 8 : 0));
  const definitionType: number = originalDefinitionType(shape);
  const fields: number[] = [
    4, 16, placement.rotation === null ? 0 : 24, 0, 36, 40,
    shape.originalTool === 0 ? 0 : 44,
    shape.originalStyle === 1 ? 0 : 45,
    0, 48, 52, 0, 0, 0, averageForce === null ? 0 : 76, 0, 0, 0,
  ];
  const root: number = builder.table(fields, 80);
  builder.inlineSequence(root + 4, page);
  builder.float32(root + 16, placement.originX);
  builder.float32(root + 20, placement.originY);
  if (placement.rotation !== null) {
    builder.float32(root + 24, placement.rotation);
  }
  builder.uint8(root + 36, definitionType);
  builder.uint8(root + 44, shape.originalTool as number);
  builder.uint8(root + 45, shape.originalStyle as number);
  builder.color(root + 48, shape.color);
  builder.float32(root + 52, shape.strokeWidth);
  if (averageForce !== null) {
    builder.float32(root + 76, averageForce);
  }
  const definition: EncodedDefinition = encodeDefinition(builder, shape);
  if (definition.type !== definitionType) {
    throw new Error('local CREATE_SHAPE definition type changed during encoding');
  }
  builder.pointer(root + 40, definition.table);
  return builder.finish(root);
}

function originalPlacement(shape: ShapeElement): OriginalShapePlacement {
  if (shape.type !== ElementType.ELLIPSE) {
    return { originX: 0, originY: 0, rotation: null };
  }
  const ellipse: EllipseElement = shape as EllipseElement;
  const rotation: number = ellipse.rotationRadians;
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  const localCenterX: number = ellipse.radiusX;
  const localCenterY: number = ellipse.radiusY;
  return {
    originX: ellipse.center.x - cosine * localCenterX + sine * localCenterY,
    originY: ellipse.center.y - sine * localCenterX - cosine * localCenterY,
    rotation: Math.abs(rotation) <= 0.0000001 ? null : rotation,
  };
}

function originalDefinitionType(shape: ShapeElement): number {
  if (shape.type === ElementType.LINE) {
    return ORIGINAL_LINE_DEFINITION;
  }
  if (shape.type === ElementType.POLYGON) {
    return ORIGINAL_POLYGON_DEFINITION;
  }
  return ORIGINAL_ELLIPSE_DEFINITION;
}

function encodeDefinition(builder: ForwardFlatBufferBuilder,
  shape: ShapeElement): EncodedDefinition {
  if (shape.type === ElementType.LINE) {
    const line: LineElement = shape as LineElement;
    const table: number = builder.table([
      4, line.controlPoint1 === null ? 0 : 12,
      line.controlPoint2 === null ? 0 : 20, 28,
      line.arrowHead === ShapeArrowHead.NONE ? 0 : 36,
    ], 40);
    builder.point(table + 4, line.start);
    if (line.controlPoint1 !== null) {
      builder.point(table + 12, line.controlPoint1);
    }
    if (line.controlPoint2 !== null) {
      builder.point(table + 20, line.controlPoint2);
    }
    builder.point(table + 28, line.end);
    if (line.arrowHead !== ShapeArrowHead.NONE) {
      builder.uint8(table + 36, 1);
    }
    return { type: ORIGINAL_LINE_DEFINITION, table: table };
  }
  if (shape.type === ElementType.POLYGON) {
    const polygon: PolygonElement = shape as PolygonElement;
    const table: number = builder.table([4], 8);
    const vector: number = builder.pointVector(polygon.vertices);
    builder.pointer(table + 4, vector);
    return { type: ORIGINAL_POLYGON_DEFINITION, table: table };
  }
  const ellipse: EllipseElement = shape as EllipseElement;
  const table: number = builder.table([0, 4], 12);
  builder.float32(table + 4, ellipse.radiusX * 2);
  builder.float32(table + 8, ellipse.radiusY * 2);
  return { type: ORIGINAL_ELLIPSE_DEFINITION, table: table };
}

function validateLocalShape(shape: ShapeElement, averageForce: number | null): void {
  if (shape.originalTool === undefined || shape.originalTool < 0 || shape.originalTool > 7 ||
    !Number.isInteger(shape.originalTool) || shape.originalStyle === undefined ||
    !Number.isInteger(shape.originalStyle) || shape.originalStyle < 1 || shape.originalStyle > 3 ||
    !validColor(shape.color) || !Number.isFinite(shape.strokeWidth) || shape.strokeWidth < 0 ||
    shape.fillColor !== null || shape.positionLocked === true ||
    shape.richText !== undefined && shape.richText.length > 0 ||
    !identityTransform(shape.transform) || averageForce !== null && !Number.isFinite(averageForce)) {
    throw new Error('local Shape cannot be represented by original CREATE_SHAPE');
  }
  if (shape.type === ElementType.LINE) {
    const line: LineElement = shape as LineElement;
    validatePoint(line.start); validatePoint(line.end);
    if (line.controlPoint1 !== null) validatePoint(line.controlPoint1);
    if (line.controlPoint2 !== null) validatePoint(line.controlPoint2);
    if (line.arrowHead !== ShapeArrowHead.NONE && line.arrowHead !== ShapeArrowHead.SINGLE) {
      throw new Error('local CREATE_SHAPE line arrow is invalid');
    }
    return;
  }
  if (shape.type === ElementType.POLYGON) {
    const polygon: PolygonElement = shape as PolygonElement;
    if (!polygon.isClosed || polygon.vertices.length < 2 ||
      polygon.vertices.length > MAX_LOCAL_SHAPE_POINTS) {
      throw new Error('local CREATE_SHAPE polygon is invalid');
    }
    polygon.vertices.forEach(validatePoint);
    return;
  }
  if (shape.type === ElementType.ELLIPSE) {
    const ellipse: EllipseElement = shape as EllipseElement;
    validatePoint(ellipse.center);
    if (!Number.isFinite(ellipse.radiusX) || ellipse.radiusX < 0 ||
      !Number.isFinite(ellipse.radiusY) || ellipse.radiusY < 0 ||
      !Number.isFinite(ellipse.rotationRadians)) {
      throw new Error('local CREATE_SHAPE ellipse is invalid');
    }
    return;
  }
  throw new Error('local CREATE_SHAPE definition is unsupported');
}

function validatePoint(point: Point2D): void {
  if (!Number.isFinite(point.x) || !Number.isFinite(point.y)) {
    throw new Error('local CREATE_SHAPE point is invalid');
  }
}

function identityTransform(transform: number[]): boolean {
  const identity: number[] = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  return transform.length === identity.length && transform.every(
    (value: number, index: number): boolean => Math.abs(value - identity[index]) <= 0.0000001);
}

function validColor(color: number): boolean {
  return Number.isSafeInteger(color) && color >= -2147483648 && color <= 4294967295;
}

class ForwardFlatBufferBuilder {
  private bytes: Uint8Array;
  private cursor: number = 4;

  constructor(capacity: number) {
    this.bytes = new Uint8Array(capacity);
  }

  table(offsets: number[], objectSize: number): number {
    const vtable: number = this.cursor;
    const vtableSize: number = 4 + offsets.length * 2;
    this.ensure(vtableSize);
    this.cursor += vtableSize;
    this.align(4);
    const table: number = this.cursor;
    this.ensure(objectSize);
    this.cursor += objectSize;
    writeU16(this.bytes, vtable, vtableSize);
    writeU16(this.bytes, vtable + 2, objectSize);
    for (let index: number = 0; index < offsets.length; index++) {
      writeU16(this.bytes, vtable + 4 + index * 2, offsets[index]);
    }
    writeU32(this.bytes, table, table - vtable);
    return table;
  }

  pointVector(points: Point2D[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.ensure(4 + points.length * 8);
    this.cursor += 4 + points.length * 8;
    writeU32(this.bytes, vector, points.length);
    for (let index: number = 0; index < points.length; index++) {
      this.point(vector + 4 + index * 8, points[index]);
    }
    return vector;
  }

  inlineSequence(offset: number, value: OriginalSequenceIdentity): void {
    writeU16(this.bytes, offset, value.siteId);
    writeU32(this.bytes, offset + 4, value.timestamp);
    writeU32(this.bytes, offset + 8, value.index);
  }

  point(offset: number, value: Point2D): void {
    this.float32(offset, value.x);
    this.float32(offset + 4, value.y);
  }

  pointer(slot: number, target: number): void {
    writeU32(this.bytes, slot, target - slot);
  }

  uint8(offset: number, value: number): void {
    this.bytes[offset] = value;
  }

  float32(offset: number, value: number): void {
    new DataView(this.bytes.buffer).setFloat32(offset, value, true);
  }

  color(offset: number, argb: number): void {
    this.bytes[offset] = argb >>> 16 & 0xFF;
    this.bytes[offset + 1] = argb >>> 8 & 0xFF;
    this.bytes[offset + 2] = argb & 0xFF;
    this.bytes[offset + 3] = argb >>> 24 & 0xFF;
  }

  finish(root: number): Uint8Array {
    writeU32(this.bytes, 0, root);
    return this.bytes.slice(0, this.cursor);
  }

  private align(value: number): void {
    while ((this.cursor & (value - 1)) !== 0) {
      this.ensure(1);
      this.cursor++;
    }
  }

  private ensure(extra: number): void {
    if (this.cursor + extra <= this.bytes.length) {
      return;
    }
    let capacity: number = this.bytes.length;
    while (capacity < this.cursor + extra) {
      capacity *= 2;
    }
    const grown: Uint8Array = new Uint8Array(capacity);
    grown.set(this.bytes);
    this.bytes = grown;
  }
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
  bytes[offset + 2] = value >>> 16 & 0xFF;
  bytes[offset + 3] = value >>> 24 & 0xFF;
}

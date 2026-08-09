import { describe, it, expect } from '@ohos/hypium';
import {
  compareIncomingSyncedOperationOrder, IncomingSyncedOperation, validateIncomingSyncedBatch,
} from '../main/ets/data/SyncedOperationInbox';
import {
  crc32Signed, parseOriginalSyncedOperationEnvelope,
} from '../main/ets/data/OriginalSyncedOperationFlatBuffer';
import {
  DeferredSyncedOperationTableType, validateDeferredSyncedOperationTableType,
} from '../main/ets/data/DeferredSyncedOperationBundle';
import {
  decodeOriginalCreatePage, decodeOriginalCreatePageTable,
  ORIGINAL_DEFAULT_PAGE_HEIGHT_MM, ORIGINAL_DEFAULT_PAGE_WIDTH_MM,
} from '../main/ets/data/OriginalCreatePageOperation';
import {
  compareOriginalSequenceIdentity, encodeOriginalPageStorageId, encodeOriginalSequenceId,
} from '../main/ets/data/OperationIdentity';
import { decodeOriginalNoteBundle } from '../main/ets/data/OriginalNoteBundlePageIdentity';
import { decodeOriginalModifyPage } from '../main/ets/data/OriginalModifyPageOperation';
import { decodeOriginalDeleteEntities } from '../main/ets/data/OriginalDeleteEntitiesOperation';
import { OriginalPageOperationApplier } from '../main/ets/data/OriginalPageOperationApplier';
import { decodeOriginalCreateInk } from '../main/ets/data/OriginalCreateInkOperation';
import { decodeOriginalAddPathElements } from
  '../main/ets/data/OriginalAddPathElementsOperation';
import { originalInkTransform,
  transformedExpandedBounds } from '../main/ets/data/OriginalInkPathCodec';
import { decodeOriginalInkPath, decodeOriginalInkPathAppend } from
  '../main/ets/data/OriginalInkPathCodec';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';

function operation(timestamp: number, serverTime: string,
  clientTime: string = serverTime, payloadType: number = 3): IncomingSyncedOperation {
  return {
    noteId: 'note', timestamp: timestamp, siteId: 7, clientTime: clientTime,
    serverTime: serverTime, schemaVersion: 1, payloadType: payloadType,
    rawOperation: flatBufferOperation(timestamp, 7, clientTime, serverTime, payloadType),
  };
}

export default function syncedOperationInboxTest() {
  describe('SyncedOperationInbox', () => {
    it('orders full unsigned server and client times without number conversion', 0, () => {
      const first = operation(1, '9007199254740993', '18446744073709551614');
      const second = operation(2, '18446744073709551615', '0');
      expect(compareIncomingSyncedOperationOrder(first, second)).assertEqual(-1);
      validateIncomingSyncedBatch('note', [first, second]);
    });

    it('rejects out-of-order and repeated operation identities before persistence', 0, () => {
      const first = operation(1, '10');
      const second = operation(2, '9');
      let rejected: number = 0;
      try {
        validateIncomingSyncedBatch('note', [first, second]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [first, operation(1, '11')]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('parses the original little-endian uq9 root without losing uint64 values', 0, () => {
      const source: IncomingSyncedOperation = operation(
        0xFFFFFFFF, '18446744073709551615', '9007199254740993', 31);
      const parsed = parseOriginalSyncedOperationEnvelope(source.rawOperation);
      expect(parsed.timestamp).assertEqual(0xFFFFFFFF);
      expect(parsed.siteId).assertEqual(7);
      expect(parsed.clientTime).assertEqual('9007199254740993');
      expect(parsed.serverTime).assertEqual('18446744073709551615');
      expect(parsed.payloadType).assertEqual(31);
      expect(parsed.payloadTypeKnown).assertTrue();
    });

    it('rejects metadata substitution and malformed FlatBuffer roots', 0, () => {
      let rejected: number = 0;
      const valid: IncomingSyncedOperation = operation(1, '10');
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, serverTime: '11' }]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, rawOperation: new Uint8Array([1, 2, 3]) }]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('uses standard signed CRC32 and the original deferred type allowlist', 0, () => {
      expect(crc32Signed(new Uint8Array([0x31, 0x32, 0x33, 0x34, 0x35,
        0x36, 0x37, 0x38, 0x39]))).assertEqual(-873187034);
      expect(validateDeferredSyncedOperationTableType('OPS_BUNDLE')).assertEqual(
        DeferredSyncedOperationTableType.OPS_BUNDLE);
      let rejected: boolean = false;
      try {
        validateDeferredSyncedOperationTableType('OPS');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('decodes original CREATE_PAGE inline SeqId and default-safe fields', 0, () => {
      const raw: Uint8Array = flatBufferCreatePage(9, 4, '11', '12',
        7, 3, 2, 2, false);
      const payload = decodeOriginalCreatePage(raw);
      expect(payload.location?.timestamp).assertEqual(7);
      expect(payload.location?.siteId).assertEqual(3);
      expect(payload.location?.index).assertEqual(2);
      expect(payload.pageCount).assertEqual(2);
      expect(payload.hasBackground).assertFalse();
      expect(payload.bookmarked).assertFalse();
      expect(ORIGINAL_DEFAULT_PAGE_WIDTH_MM).assertEqual(215.9);
      expect(ORIGINAL_DEFAULT_PAGE_HEIGHT_MM).assertEqual(279.4);
      const rootPayload = decodeOriginalCreatePage(flatBufferCreatePageBackground());
      expect(rootPayload.location === null).assertTrue();
      expect(rootPayload.hasBackground).assertTrue();
      expect(rootPayload.bookmarked).assertTrue();
      expect(rootPayload.background?.background.paper?.colorA).assertEqual(255);
    });

    it('keeps original SeqId comparison and note-scoped storage IDs', 0, () => {
      const older = { timestamp: 5, siteId: 2, index: 0 };
      const newer = { timestamp: 6, siteId: 1, index: 0 };
      expect(compareOriginalSequenceIdentity(older, newer)).assertEqual(-1);
      expect(compareOriginalSequenceIdentity({ timestamp: 5, siteId: 2, index: 1 }, older))
        .assertEqual(-1);
      expect(encodeOriginalSequenceId(older)).assertEqual('seq:5:2:0');
      expect(encodeOriginalPageStorageId('a', older)).assertEqual('original-page:1:a:seq:5:2:0');
    });

    it('decodes original MODIFY_PAGE page vector and nullable SeqMove target', 0, () => {
      const payload = decodeOriginalModifyPage(flatBufferModifyPage());
      expect(payload.pages.length).assertEqual(2);
      expect(payload.pages[0].timestamp).assertEqual(10);
      expect(payload.pages[0].siteId).assertEqual(1);
      expect(payload.pages[0].index).assertEqual(2);
      expect(payload.pages[1].timestamp).assertEqual(20);
      expect(payload.pages[1].siteId).assertEqual(3);
      expect(payload.pages[1].index).assertEqual(4);
      expect(payload.hasMove).assertTrue();
      expect(payload.moveTo?.timestamp).assertEqual(30);
      expect(payload.moveTo?.siteId).assertEqual(5);
      expect(payload.moveTo?.index).assertEqual(6);
      expect(payload.hasBackground).assertFalse();
      expect(payload.hasBookmarked).assertFalse();
      const applier = new OriginalPageOperationApplier();
      expect(applier.supports(3)).assertTrue();
      expect(applier.supports(4)).assertTrue();
      expect(applier.supports(25)).assertTrue();
      expect(applier.supports(15)).assertTrue();
      expect(applier.supports(16)).assertTrue();
      expect(applier.supports(5)).assertFalse();
    });

    it('decodes original CREATE_INK path attributes, transform and uint64 z-index', 0, () => {
      const payload = decodeOriginalCreateInk(flatBufferCreateInk(), '123');
      expect(payload.page.timestamp).assertEqual(10);
      expect(payload.page.siteId).assertEqual(1);
      expect(payload.page.index).assertEqual(2);
      expect(payload.originX).assertEqual(12);
      expect(payload.originY).assertEqual(34);
      expect(Math.abs(payload.rotation - Math.PI / 2) < 0.000001).assertTrue();
      expect(payload.scaleX).assertEqual(2);
      expect(payload.scaleY).assertEqual(3);
      expect(payload.tool).assertEqual(0);
      expect(payload.style).assertEqual(0);
      expect(payload.color).assertEqual(-2146823138);
      expect(payload.width).assertEqual(4);
      expect(payload.zIndex).assertEqual('18446744073709551615');
      expect(payload.path?.pathPoints.length).assertEqual(3);
      expect(payload.path?.cubicSegments.length).assertEqual(2);
      expect(payload.path?.pathPoints[0].position.x).assertEqual(1);
      expect(payload.path?.pathPoints[0].widthFactor).assertEqual(1);
      expect(payload.path?.pathPoints[1].position.x).assertEqual(6);
      expect(payload.path?.pathPoints[1].pressure).assertEqual(0.25);
      expect(Math.abs((payload.path?.pathPoints[1].altitudeAngleRadians as number) - Math.PI / 2) <
        0.000001).assertTrue();
      expect(Math.abs((payload.path?.pathPoints[1].azimuthUnitX as number)) < 0.000001).assertTrue();
      expect(Math.abs((payload.path?.pathPoints[1].azimuthUnitY as number) - 1) < 0.000001).assertTrue();
      expect(payload.path?.localBounds.left).assertEqual(1);
      expect(payload.path?.localBounds.top).assertEqual(-3);
      expect(payload.path?.localBounds.right).assertEqual(20);
      expect(payload.path?.localBounds.bottom).assertEqual(9);
      expect(payload.centerPathBytes?.length).assertEqual(64);
      const bounds = transformedExpandedBounds(payload.path?.localBounds as Rect2D, payload.width,
        originalInkTransform(payload.originX, payload.originY, payload.rotation,
          payload.scaleX, payload.scaleY));
      expect(Math.abs(bounds.left + 39) < 0.00001).assertTrue();
      expect(Math.abs(bounds.top - 20) < 0.00001).assertTrue();
      expect(Math.abs(bounds.right - 45) < 0.00001).assertTrue();
      expect(Math.abs(bounds.bottom - 90) < 0.00001).assertTrue();
      const unknownEnums = decodeOriginalCreateInk(flatBufferCreateInk(255, 255), '123');
      expect(unknownEnums.tool).assertEqual(0);
      expect(unknownEnums.style).assertEqual(0);
      const flipped = originalInkTransform(0, 0, 0, -2, 0);
      expect(flipped[0]).assertEqual(-2);
      expect(flipped[4]).assertEqual(0);
    });

    it('decodes original ADD_PATH_ELEMENTS target and keeps the raw quadratic hull', 0, () => {
      const payload = decodeOriginalAddPathElements(flatBufferAddPathElements());
      expect(payload.ink.timestamp).assertEqual(20);
      expect(payload.ink.siteId).assertEqual(2);
      expect(payload.centerPathEstimatedElements === null).assertTrue();
      const append = decodeOriginalInkPathAppend(
        payload.centerPathElements as Uint8Array, { x: 0, y: 0 });
      expect(append.pathPoints.length).assertEqual(1);
      expect(append.cubicSegments.length).assertEqual(1);
      expect(append.pathPoints[0].position.x).assertEqual(10);
      expect(append.localBounds.left).assertEqual(0);
      expect(append.localBounds.right).assertEqual(100);
      expect(append.localBounds.bottom).assertEqual(100);
      expect(append.attributed).assertTrue();
    });

    it('decodes the original big-endian half-float coordinate path variant', 0, () => {
      const path = decodeOriginalInkPath(new Uint8Array([
        0, 0, 2,
        3, 0x3C, 0, 0x40, 0, 0x3C, 0, 0x38, 0, 0, 0,
        2, 0x42, 0, 0x44, 0, 0x3C, 0, 0x38, 0, 255, 64,
      ]));
      expect(path.pathPoints.length).assertEqual(2);
      expect(path.pathPoints[0].position.x).assertEqual(1);
      expect(path.pathPoints[0].position.y).assertEqual(2);
      expect(path.pathPoints[1].position.x).assertEqual(3);
      expect(path.pathPoints[1].position.y).assertEqual(4);
    });

    it('decodes background-only MODIFY_PAGE and preserves an explicit null setter', 0, () => {
      const payload = decodeOriginalModifyPage(flatBufferModifyPageBackground(true));
      expect(payload.pages.length).assertEqual(1);
      expect(payload.hasMove).assertFalse();
      expect(payload.hasBackground).assertTrue();
      expect(payload.background?.background.paper?.flair).assertEqual(2);
      expect(payload.background?.background.paper?.flairSpacingPt).assertEqual(18);
      expect(payload.background?.background.paper?.colorR).assertEqual(244);
      expect(payload.background?.background.paper?.colorA).assertEqual(255);
      expect(payload.background?.widthMm).assertEqual(215.9);
      expect(payload.background?.heightMm).assertEqual(279.4);
      const clear = decodeOriginalModifyPage(flatBufferModifyPageBackground(false));
      expect(clear.hasBackground).assertTrue();
      expect(clear.background === null).assertTrue();
    });

    it('decodes original DELETE_ENTITIES page tombstones independently from entities', 0, () => {
      const payload = decodeOriginalDeleteEntities(flatBufferDeleteEntities());
      expect(payload.entityDeleteCount).assertEqual(1);
      expect(payload.entityUndeleteCount).assertEqual(1);
      expect(payload.pageDeletes.length).assertEqual(2);
      expect(payload.pageDeletes[0].timestamp).assertEqual(10);
      expect(payload.pageDeletes[0].siteId).assertEqual(1);
      expect(payload.pageDeletes[0].index).assertEqual(2);
      expect(payload.pageUndeletes.length).assertEqual(1);
      expect(payload.pageUndeletes[0].timestamp).assertEqual(20);
      expect(payload.pageUndeletes[0].siteId).assertEqual(3);
      expect(payload.pageUndeletes[0].index).assertEqual(4);
    });

    it('decodes original NOTE_BUNDLE metadata and nested operation tables', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundle());
      expect(bundle.noteId).assertEqual('00112233-4455-6677-8899-aabbccddeeff');
      expect(bundle.editorSiteId).assertEqual(9);
      expect(bundle.schemaVersion).assertEqual(7);
      expect(bundle.operations.length).assertEqual(2);
      expect(bundle.operations[0].timestamp).assertEqual(10);
      expect(bundle.operations[0].siteId).assertEqual(1);
      expect(bundle.operations[0].payloadType).assertEqual(3);
      expect(bundle.operations[0].clientTime).assertEqual('11');
      expect(bundle.operations[0].serverTime).assertEqual('12');
      const child = decodeOriginalCreatePageTable(bundle.operations[1].payload);
      expect(child.location?.timestamp).assertEqual(10);
      expect(child.location?.siteId).assertEqual(1);
      expect(child.location?.index).assertEqual(0);
      expect(child.pageCount).assertEqual(1);
    });
  });
}

function flatBufferNoteBundle(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(260);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 20);
  writeU16(bytes, 6, 40);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 0);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 14, 24);
  writeU16(bytes, 16, 0);
  writeU16(bytes, 18, 28);
  writeU16(bytes, 20, 32);
  writeU16(bytes, 22, 36);
  writeU32(bytes, 24, 20);
  const uuid: number[] = [0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88,
    0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00];
  for (let index: number = 0; index < uuid.length; index++) {
    bytes[28 + index] = uuid[index];
  }
  writeU16(bytes, 44, 9);
  writeU32(bytes, 48, 20);
  writeU32(bytes, 52, 24);
  writeU32(bytes, 56, 28);
  writeU16(bytes, 60, 7);
  writeU32(bytes, 68, 1);
  bytes[72] = 0x65;
  writeU32(bytes, 76, 1);
  bytes[80] = 0x63;
  writeU32(bytes, 84, 2);
  writeU32(bytes, 88, 28);
  writeU32(bytes, 92, 80);
  writeNoteBundleOperation(bytes, 96, 116, 1, 10, '11', '12', 220);
  writeNoteBundleOperation(bytes, 152, 172, 2, 20, '21', '22', 240);
  writeU16(bytes, 208, 10);
  writeU16(bytes, 210, 8);
  writeU16(bytes, 212, 0);
  writeU16(bytes, 214, 0);
  writeU16(bytes, 216, 4);
  writeU32(bytes, 220, 12);
  writeU32(bytes, 224, 1);
  writeU16(bytes, 228, 10);
  writeU16(bytes, 230, 20);
  writeU16(bytes, 232, 4);
  writeU16(bytes, 234, 0);
  writeU16(bytes, 236, 16);
  writeU32(bytes, 240, 12);
  writeU16(bytes, 244, 1);
  writeU32(bytes, 248, 10);
  writeU32(bytes, 252, 0);
  writeU32(bytes, 256, 1);
  return bytes;
}

function writeNoteBundleOperation(bytes: Uint8Array, vtable: number, table: number,
  siteId: number, timestamp: number, clientTime: string, serverTime: string,
  payloadTable: number): void {
  writeU16(bytes, vtable, 18);
  writeU16(bytes, vtable + 2, 36);
  writeU16(bytes, vtable + 4, 4);
  writeU16(bytes, vtable + 6, 12);
  writeU16(bytes, vtable + 8, 20);
  writeU16(bytes, vtable + 10, 0);
  writeU16(bytes, vtable + 12, 28);
  writeU16(bytes, vtable + 14, 32);
  writeU16(bytes, vtable + 16, 0);
  writeU32(bytes, table, table - vtable);
  writeU16(bytes, table + 4, siteId);
  writeU32(bytes, table + 8, timestamp);
  writeDecimalU64(bytes, table + 12, clientTime);
  writeDecimalU64(bytes, table + 20, serverTime);
  bytes[table + 28] = 3;
  writeU32(bytes, table + 32, payloadTable - (table + 32));
}

function flatBufferCreatePage(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, locationTimestamp: number, locationSite: number,
  locationIndex: number, pageCount: number, bookmarked: boolean,
  hasLocation: boolean = true, hasBackground: boolean = false): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(96);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = 3;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 24);
  writeU16(bytes, 64, hasLocation ? 4 : 0);
  writeU16(bytes, 66, hasBackground ? 4 : 0);
  writeU16(bytes, 68, 16);
  writeU16(bytes, 70, 20);
  writeU32(bytes, 72, 12);
  writeU16(bytes, 76, locationSite);
  writeU32(bytes, 80, locationTimestamp);
  writeU32(bytes, 84, locationIndex);
  writeU32(bytes, 88, pageCount);
  bytes[92] = bookmarked ? 1 : 0;
  return bytes;
}

function flatBufferModifyPage(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(156);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, 7);
  writeU32(bytes, 32, 40);
  writeDecimalU64(bytes, 36, '41');
  writeDecimalU64(bytes, 44, '42');
  bytes[52] = 4;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 12);
  writeU16(bytes, 64, 4);
  writeU16(bytes, 66, 8);
  writeU32(bytes, 72, 12);
  writeU32(bytes, 76, 28);
  writeU32(bytes, 80, 60);

  writeU32(bytes, 104, 2);
  writeU16(bytes, 108, 1);
  writeU32(bytes, 112, 10);
  writeU32(bytes, 116, 2);
  writeU16(bytes, 120, 3);
  writeU32(bytes, 124, 20);
  writeU32(bytes, 128, 4);

  writeU16(bytes, 132, 6);
  writeU16(bytes, 134, 16);
  writeU16(bytes, 136, 4);
  writeU32(bytes, 140, 8);
  writeU16(bytes, 144, 5);
  writeU32(bytes, 148, 30);
  writeU32(bytes, 152, 6);
  return bytes;
}

class FixtureFlatBufferBuilder {
  private bytes: Uint8Array = new Uint8Array(512);
  private cursor: number = 4;

  table(offsets: number[], objectSize: number): number {
    const vtable: number = this.cursor;
    const vtableSize: number = 4 + offsets.length * 2;
    this.cursor += vtableSize;
    this.align(4);
    const table: number = this.cursor;
    this.cursor += objectSize;
    writeU16(this.bytes, vtable, vtableSize);
    writeU16(this.bytes, vtable + 2, objectSize);
    for (let index: number = 0; index < offsets.length; index++) {
      writeU16(this.bytes, vtable + 4 + index * 2, offsets[index]);
    }
    writeU32(this.bytes, table, table - vtable);
    return table;
  }

  sequenceVector(timestamp: number, siteId: number, index: number): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 16;
    writeU32(this.bytes, vector, 1);
    writeU16(this.bytes, vector + 4, siteId);
    writeU32(this.bytes, vector + 8, timestamp);
    writeU32(this.bytes, vector + 12, index);
    return vector;
  }

  byteVector(values: number[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length + 1;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      this.bytes[vector + 4 + index] = values[index];
    }
    this.bytes[vector + 4 + values.length] = 0;
    return vector;
  }

  pointer(slot: number, target: number): void {
    writeU32(this.bytes, slot, target - slot);
  }

  uint8(offset: number, value: number): void {
    this.bytes[offset] = value;
  }

  uint16(offset: number, value: number): void {
    writeU16(this.bytes, offset, value);
  }

  uint32(offset: number, value: number): void {
    writeU32(this.bytes, offset, value);
  }

  float32(offset: number, value: number): void {
    const source: Uint8Array = new Uint8Array(new Float32Array([value]).buffer);
    for (let index: number = 0; index < 4; index++) {
      this.bytes[offset + index] = source[index];
    }
  }

  color(offset: number, values: number[]): void {
    for (let index: number = 0; index < values.length; index++) {
      this.bytes[offset + index] = values[index];
    }
  }

  finish(root: number): Uint8Array {
    writeU32(this.bytes, 0, root);
    return this.bytes.slice(0, this.cursor);
  }

  private align(value: number): void {
    while ((this.cursor & (value - 1)) !== 0) {
      this.cursor++;
    }
  }
}

function flatBufferCreateInk(tool: number = 0, style: number = 0): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 15);
  const fields: number[] = [4, 16, 24, 28, 36, 37, 0, 40, 44, 48,
    0, 0, 0, 0, 56, 0, 0, 0, 0, 0];
  const ink: number = builder.table(fields, 64);
  builder.pointer(root + 32, ink);
  builder.uint16(ink + 4, 1);
  builder.uint32(ink + 8, 10);
  builder.uint32(ink + 12, 2);
  builder.float32(ink + 16, 12);
  builder.float32(ink + 20, 34);
  builder.float32(ink + 24, Math.PI / 2);
  builder.float32(ink + 28, 2);
  builder.float32(ink + 32, 3);
  builder.uint8(ink + 36, tool);
  builder.uint8(ink + 37, style);
  builder.color(ink + 40, [10, 20, 30, 128]);
  builder.float32(ink + 44, 4);
  writeDecimalU64At(builder, ink + 56, '18446744073709551615');
  const path: number[] = [1, 0, 3];
  appendAttributedPathElement(path, 3, [{ x: 1, y: 2 }], 0x3C00, 0x3800, 0, 0);
  appendAttributedPathElement(path, 0,
    [{ x: 20, y: -3 }, { x: 4, y: 5 }, { x: 6, y: 7 }], 0x3800, 0x3400, 255, 64);
  appendAttributedPathElement(path, 2, [{ x: 8, y: 9 }], 0x3C00, 0x3800, 128, 128);
  const vector: number = builder.byteVector(path);
  builder.pointer(ink + 48, vector);
  return builder.finish(root);
}

function flatBufferAddPathElements(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 91);
  writeDecimalU64At(builder, root + 12, '125');
  writeDecimalU64At(builder, root + 20, '126');
  builder.uint8(root + 28, 16);
  const add: number = builder.table([4, 12, 0], 16);
  builder.pointer(root + 32, add);
  builder.uint16(add + 4, 2);
  builder.uint32(add + 8, 20);
  const path: number[] = [1, 0, 1];
  appendAttributedPathElement(path, 1,
    [{ x: 100, y: 100 }, { x: 10, y: 0 }], 0x3C00, 0x3800, 255, 0);
  const vector: number = builder.byteVector(path);
  builder.pointer(add + 12, vector);
  return builder.finish(root);
}

function appendAttributedPathElement(target: number[], type: number,
  points: { x: number, y: number }[], width: number, force: number,
  altitude: number, azimuth: number): void {
  target.push(type);
  for (const point of points) {
    appendFloat32(target, point.x);
    appendFloat32(target, point.y);
  }
  target.push((width >>> 8) & 0xFF, width & 0xFF,
    (force >>> 8) & 0xFF, force & 0xFF, altitude, azimuth);
}

function appendFloat32(target: number[], value: number): void {
  const bytes: Uint8Array = new Uint8Array(new Float32Array([value]).buffer);
  for (let index: number = 0; index < 4; index++) {
    target.push(bytes[index]);
  }
}

function writeDecimalU64At(builder: FixtureFlatBufferBuilder,
  offset: number, decimal: string): void {
  let remaining: string = decimal;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let carry: number = 0;
    for (let digit: number = 0; digit < remaining.length; digit++) {
      const value: number = carry * 10 + remaining.charCodeAt(digit) - 0x30;
      const part: number = Math.floor(value / 256);
      carry = value % 256;
      if (quotient.length > 0 || part > 0) {
        quotient += part.toString();
      }
    }
    builder.uint8(offset + index, carry);
    remaining = quotient.length === 0 ? '0' : quotient;
  }
}

function flatBufferModifyPageBackground(includeValue: boolean): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  builder.uint8(root + 28, 4);
  const modify: number = builder.table([4, 0, 8, 0], 12);
  builder.pointer(root + 32, modify);
  const pages: number = builder.sequenceVector(10, 1, 2);
  builder.pointer(modify + 4, pages);
  const setter: number = builder.table([includeValue ? 4 : 0], includeValue ? 8 : 4);
  builder.pointer(modify + 8, setter);
  if (includeValue) {
    const background: number = builder.table([4, 0, 8, 12, 0], 20);
    builder.pointer(setter + 4, background);
    builder.float32(background + 8, 0);
    builder.float32(background + 12, 612);
    builder.float32(background + 16, 792);
    const paper: number = builder.table([4, 8, 12, 13, 16, 20], 24);
    builder.pointer(background + 4, paper);
    builder.uint8(paper + 4, 2);
    builder.float32(paper + 8, 18);
    builder.uint8(paper + 12, 1);
    builder.uint8(paper + 13, 1);
    builder.color(paper + 16, [244, 245, 246, 255]);
    builder.uint8(paper + 20, 7);
  }
  return builder.finish(root);
}

function flatBufferCreatePageBackground(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 4);
  builder.uint32(root + 8, 10);
  builder.uint8(root + 28, 3);
  const create: number = builder.table([0, 4, 8, 12], 16);
  builder.pointer(root + 32, create);
  builder.uint32(create + 8, 1);
  builder.uint8(create + 12, 1);
  const background: number = builder.table([4, 0, 8, 12, 0], 20);
  builder.pointer(create + 4, background);
  builder.float32(background + 8, 0);
  builder.float32(background + 12, 612);
  builder.float32(background + 16, 792);
  const paper: number = builder.table([4, 8, 12, 13, 16, 20], 24);
  builder.pointer(background + 4, paper);
  builder.uint8(paper + 4, 2);
  builder.float32(paper + 8, 18);
  builder.uint8(paper + 12, 1);
  builder.uint8(paper + 13, 1);
  builder.color(paper + 16, [244, 245, 246, 255]);
  builder.uint8(paper + 20, 7);
  return builder.finish(root);
}

function flatBufferDeleteEntities(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(164);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, 7);
  writeU32(bytes, 32, 50);
  writeDecimalU64(bytes, 36, '51');
  writeDecimalU64(bytes, 44, '52');
  bytes[52] = 25;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 20);
  writeU16(bytes, 64, 4);
  writeU16(bytes, 66, 8);
  writeU16(bytes, 68, 12);
  writeU16(bytes, 70, 16);
  writeU32(bytes, 72, 12);
  writeU32(bytes, 76, 20);
  writeU32(bytes, 80, 28);
  writeU32(bytes, 84, 36);
  writeU32(bytes, 88, 60);

  writeU32(bytes, 96, 1);
  writeU16(bytes, 100, 8);
  writeU32(bytes, 104, 9);
  writeU32(bytes, 108, 1);
  writeU16(bytes, 112, 10);
  writeU32(bytes, 116, 11);

  writeU32(bytes, 120, 2);
  writeU16(bytes, 124, 1);
  writeU32(bytes, 128, 10);
  writeU32(bytes, 132, 2);
  writeU16(bytes, 136, 5);
  writeU32(bytes, 140, 30);
  writeU32(bytes, 144, 6);

  writeU32(bytes, 148, 1);
  writeU16(bytes, 152, 3);
  writeU32(bytes, 156, 20);
  writeU32(bytes, 160, 4);
  return bytes;
}

function flatBufferOperation(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, payloadType: number): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(68);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = payloadType;
  writeU32(bytes, 56, 8);
  writeU16(bytes, 60, 4);
  writeU16(bytes, 62, 4);
  writeU32(bytes, 64, 4);
  return bytes;
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
  bytes[offset + 2] = Math.floor(value / 0x10000) & 0xFF;
  bytes[offset + 3] = Math.floor(value / 0x1000000) & 0xFF;
}

function writeDecimalU64(bytes: Uint8Array, offset: number, decimal: string): void {
  let remaining: string = decimal;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let carry: number = 0;
    for (let digit: number = 0; digit < remaining.length; digit++) {
      const value: number = carry * 10 + remaining.charCodeAt(digit) - 0x30;
      const part: number = Math.floor(value / 256);
      carry = value % 256;
      if (quotient.length > 0 || part > 0) {
        quotient += part.toString();
      }
    }
    bytes[offset + index] = carry;
    remaining = quotient.length === 0 ? '0' : quotient;
  }
}

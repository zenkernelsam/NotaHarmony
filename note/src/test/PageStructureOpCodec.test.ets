import { describe, it, expect } from '@ohos/hypium';
import { OpType } from '../main/ets/core/model/OpTypes';
import { PageInfo, PageOrientation, PaperSize, PaperTemplate } from '../main/ets/core/model/NoteTypes';
import { serializePageBackground } from '../main/ets/core/model/PageBackgroundModel';
import {
  BinaryOpWriter, encodeOperationString,
} from '../main/ets/data/BinaryOpCodec';
import {
  classifyPageStructureMutation, createPageStructureMutation, decodePageStructureMutation,
  encodePageStructureMutation, PageStructureMutation, PageStructureReplayResult,
  replayPageStructureMutation,
} from '../main/ets/data/PageStructureOpCodec';

export default function pageStructureOpCodecTest() {
  describe('PageStructureOpCodec', () => {
    it('round-trips create and delete with strict bidirectional replay', 0, () => {
      const first: PageInfo = page('first', 0, PaperTemplate.PLAIN);
      const second: PageInfo = page('second-中文', 1, PaperTemplate.GRID);
      second.originalPageInAsset = 7;
      second.background = {
        schemaVersion: 1,
        paper: { flair: 2, flairSpacingPt: 18, flairBleeds: true, flairCentered: false,
          colorR: 250, colorG: 249, colorB: 248, colorA: 255, legacyPaperIndex: null },
        rotationRadians: 0, sourceWidthPt: 595, sourceHeightPt: 842,
        margins: { topPt: 10, bottomPt: 10, leftPt: 12, rightPt: 12 },
      };
      const create: PageStructureMutation = roundTrip(
        createPageStructureMutation(3, 4, [first], [first, second]));
      expect(classifyPageStructureMutation(create)).assertEqual(OpType.CREATE_PAGE);
      assertReplay([first], 3, create, true, [first, second], 4);
      assertReplay([first, second], 4, create, false, [first], 3);

      const retained: PageInfo = page('second-中文', 0, PaperTemplate.GRID);
      const remove: PageStructureMutation = roundTrip(
        createPageStructureMutation(4, 5, [first, second], [retained]));
      expect(classifyPageStructureMutation(remove)).assertEqual(OpType.DELETE_PAGE);
      assertReplay([first, second], 4, remove, true, [retained], 5);
      assertReplay([retained], 5, remove, false, [first, second], 4);
    });

    it('distinguishes settings changes from reorder operations', 0, () => {
      const first: PageInfo = page('a', 0, PaperTemplate.PLAIN);
      const second: PageInfo = page('b', 1, PaperTemplate.GRID);
      const changed: PageInfo = page('a', 0, PaperTemplate.LINES);
      changed.widthMm = 297;
      changed.heightMm = 210;
      changed.orientation = PageOrientation.LANDSCAPE;
      const update: PageStructureMutation = roundTrip(
        createPageStructureMutation(8, 9, [first, second], [changed, second]));
      expect(classifyPageStructureMutation(update)).assertEqual(OpType.UPDATE_PAGE);

      const movedSecond: PageInfo = page('b', 0, PaperTemplate.GRID);
      const movedFirst: PageInfo = page('a', 1, PaperTemplate.PLAIN);
      const reorder: PageStructureMutation = roundTrip(
        createPageStructureMutation(9, 10, [first, second], [movedSecond, movedFirst]));
      expect(classifyPageStructureMutation(reorder)).assertEqual(OpType.REORDER_PAGES);
      assertReplay([first, second], 9, reorder, true, [movedSecond, movedFirst], 10);
    });

    it('rejects stale state, composite changes and corrupt bytes', 0, () => {
      const first: PageInfo = page('a', 0, PaperTemplate.PLAIN);
      const second: PageInfo = page('b', 1, PaperTemplate.GRID);
      const mutation: PageStructureMutation = createPageStructureMutation(0, 1, [first], [first, second]);
      expectThrow((): void => { replayPageStructureMutation([first], 2, mutation, true); });
      expectThrow((): void => {
        replayPageStructureMutation([page('wrong', 0, PaperTemplate.PLAIN)], 0, mutation, true);
      });
      expectThrow((): void => { createPageStructureMutation(0, 1, [first], [first]); });
      expectThrow((): void => {
        createPageStructureMutation(0, 1, [first, second], [
          page('b', 0, PaperTemplate.LINES), page('a', 1, PaperTemplate.PLAIN),
        ]);
      });
      expectThrow((): void => {
        createPageStructureMutation(0, 1, [first], [first, page('a', 1, PaperTemplate.GRID)]);
      });

      const encoded: Uint8Array = encodePageStructureMutation(mutation);
      expectThrow((): void => { decodePageStructureMutation(encoded.slice(0, encoded.length - 1)); });
      const trailing = new Uint8Array(encoded.length + 1);
      trailing.set(encoded);
      expectThrow((): void => { decodePageStructureMutation(trailing); });
    });

    it('keeps legacy NPG1 page history readable', 0, () => {
      const first: PageInfo = page('legacy-a', 0, PaperTemplate.PLAIN);
      const second: PageInfo = page('legacy-b', 1, PaperTemplate.GRID);
      const decoded: PageStructureMutation = decodePageStructureMutation(
        encodeLegacyMutation(4, 5, [first], [first, second]));
      expect(classifyPageStructureMutation(decoded)).assertEqual(OpType.CREATE_PAGE);
      expect(decoded.afterPages.length).assertEqual(2);
      expect(decoded.afterPages[1].background === undefined ||
        decoded.afterPages[1].background === null).assertTrue();
    });
  });
}

function page(pageId: string, pageIndex: number, template: PaperTemplate): PageInfo {
  return {
    pageId: pageId,
    pageIndex: pageIndex,
    size: PaperSize.A4,
    template: template,
    orientation: PageOrientation.PORTRAIT,
    widthMm: 210,
    heightMm: 297,
  };
}

function roundTrip(mutation: PageStructureMutation): PageStructureMutation {
  return decodePageStructureMutation(encodePageStructureMutation(mutation));
}

function assertReplay(current: PageInfo[], revision: number, mutation: PageStructureMutation,
  forward: boolean, expectedPages: PageInfo[], expectedRevision: number): void {
  const result: PageStructureReplayResult = replayPageStructureMutation(
    current, revision, mutation, forward);
  expect(result.revision).assertEqual(expectedRevision);
  expect(result.pages.length).assertEqual(expectedPages.length);
  for (let index: number = 0; index < expectedPages.length; index++) {
    expect(result.pages[index].pageId).assertEqual(expectedPages[index].pageId);
    expect(result.pages[index].pageIndex).assertEqual(expectedPages[index].pageIndex);
    expect(result.pages[index].size).assertEqual(expectedPages[index].size);
    expect(result.pages[index].template).assertEqual(expectedPages[index].template);
    expect(result.pages[index].orientation).assertEqual(expectedPages[index].orientation);
    expect(result.pages[index].widthMm).assertEqual(expectedPages[index].widthMm);
    expect(result.pages[index].heightMm).assertEqual(expectedPages[index].heightMm);
    expect(result.pages[index].originalPageInAsset).assertEqual(
      expectedPages[index].originalPageInAsset);
    expect(serializePageBackground(result.pages[index].background))
      .assertEqual(serializePageBackground(expectedPages[index].background));
  }
}

function expectThrow(block: () => void): void {
  let rejected: boolean = false;
  try {
    block();
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}

function encodeLegacyMutation(fromRevision: number, toRevision: number,
  before: PageInfo[], after: PageInfo[]): Uint8Array {
  const size: number = 20 + legacyPagesSize(before) + legacyPagesSize(after);
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array([0x4E, 0x50, 0x47, 0x31]));
  writer.writeSafeInteger(fromRevision);
  writer.writeSafeInteger(toRevision);
  writeLegacyPages(writer, before);
  writeLegacyPages(writer, after);
  return writer.finish();
}

function legacyPagesSize(pages: PageInfo[]): number {
  let size: number = 4;
  for (const value of pages) {
    size += 4 + encodeOperationString(value.pageId, 'legacy ID').length + 8 + 4 + 4 + 4 +
      4 + value.widthMm.toString().length + 4 + value.heightMm.toString().length;
  }
  return size;
}

function writeLegacyPages(writer: BinaryOpWriter, pages: PageInfo[]): void {
  writer.writeUint32(pages.length);
  for (const value of pages) {
    writer.writeSizedBytes(encodeOperationString(value.pageId, 'legacy ID'));
    writer.writeSafeInteger(value.pageIndex);
    writer.writeUint32(value.size);
    writer.writeUint32(value.template);
    writer.writeUint32(value.orientation);
    writer.writeSizedBytes(encodeOperationString(value.widthMm.toString(), 'legacy width'));
    writer.writeSizedBytes(encodeOperationString(value.heightMm.toString(), 'legacy height'));
  }
}

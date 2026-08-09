import { OpType } from '../core/model/OpTypes';
import { PageInfo, PageOrientation, PaperSize, PaperTemplate } from '../core/model/NoteTypes';
import { validatePageDimensions } from '../core/model/PageCoordinateSpace';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
} from './BinaryOpCodec';

const MAGIC: number[] = [0x4E, 0x50, 0x47, 0x31]; // NPG1
const MAX_OPERATION_PAGES: number = 10000;

export interface PageStructureMutation {
  fromRevision: number;
  toRevision: number;
  beforePages: PageInfo[];
  afterPages: PageInfo[];
}

export interface PageStructureReplayResult {
  revision: number;
  pages: PageInfo[];
}

interface EncodedPage {
  value: PageInfo;
  pageId: Uint8Array;
  width: Uint8Array;
  height: Uint8Array;
}

export function createPageStructureMutation(fromRevision: number, toRevision: number,
  beforePages: PageInfo[], afterPages: PageInfo[]): PageStructureMutation {
  const mutation: PageStructureMutation = {
    fromRevision: fromRevision,
    toRevision: toRevision,
    beforePages: clonePages(beforePages),
    afterPages: clonePages(afterPages),
  };
  classifyPageStructureMutation(mutation);
  return mutation;
}

export function classifyPageStructureMutation(mutation: PageStructureMutation): OpType {
  validateMutationIdentity(mutation);
  validatePages(mutation.beforePages, 'before pages');
  validatePages(mutation.afterPages, 'after pages');
  const beforeIds: string[] = pageIds(mutation.beforePages);
  const afterIds: string[] = pageIds(mutation.afterPages);

  if (afterIds.length === beforeIds.length + 1) {
    validateSingleMembershipChange(mutation.beforePages, mutation.afterPages, true);
    return OpType.CREATE_PAGE;
  }
  if (beforeIds.length === afterIds.length + 1) {
    validateSingleMembershipChange(mutation.beforePages, mutation.afterPages, false);
    return OpType.DELETE_PAGE;
  }
  if (!sameMembers(beforeIds, afterIds)) {
    throw new Error('page mutation changes more than one page identity');
  }

  let settingsChanges: number = 0;
  for (const before of mutation.beforePages) {
    const after: PageInfo = findPage(mutation.afterPages, before.pageId);
    if (!samePageSettings(before, after)) {
      settingsChanges++;
    }
  }
  const reordered: boolean = !sameStrings(beforeIds, afterIds);
  if (settingsChanges === 0 && reordered) {
    return OpType.REORDER_PAGES;
  }
  if (settingsChanges === 1 && !reordered) {
    return OpType.UPDATE_PAGE;
  }
  if (settingsChanges === 0) {
    throw new Error('page mutation does not change state');
  }
  throw new Error('page mutation combines unrelated page changes');
}

export function replayPageStructureMutation(currentPages: PageInfo[], currentRevision: number,
  mutation: PageStructureMutation, forward: boolean): PageStructureReplayResult {
  const expectedRevision: number = forward ? mutation.fromRevision : mutation.toRevision;
  if (!Number.isSafeInteger(currentRevision) || currentRevision !== expectedRevision) {
    throw new Error('page mutation source revision mismatch');
  }
  classifyPageStructureMutation(mutation);
  const source: PageInfo[] = forward ? mutation.beforePages : mutation.afterPages;
  const target: PageInfo[] = forward ? mutation.afterPages : mutation.beforePages;
  validatePages(currentPages, 'replay source');
  if (!samePages(currentPages, source)) {
    throw new Error('page mutation source pages mismatch');
  }
  return {
    revision: forward ? mutation.toRevision : mutation.fromRevision,
    pages: clonePages(target),
  };
}

export function encodePageStructureMutation(mutation: PageStructureMutation): Uint8Array {
  classifyPageStructureMutation(mutation);
  const before: EncodedPage[] = encodePages(mutation.beforePages);
  const after: EncodedPage[] = encodePages(mutation.afterPages);
  const size: number = MAGIC.length + 8 + 8 + encodedPagesSize(before) + encodedPagesSize(after);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('page structure operation is too large');
  }
  const writer = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writePages(writer, before);
  writePages(writer, after);
  return writer.finish();
}

export function decodePageStructureMutation(bytes: Uint8Array): PageStructureMutation {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: PageStructureMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    beforePages: readPages(reader),
    afterPages: readPages(reader),
  };
  if (!reader.atEnd()) {
    throw new Error('page structure operation has trailing bytes');
  }
  classifyPageStructureMutation(mutation);
  return mutation;
}

function validateMutationIdentity(mutation: PageStructureMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    !Number.isSafeInteger(mutation.toRevision) || mutation.toRevision !== mutation.fromRevision + 1) {
    throw new Error('page structure revision is invalid');
  }
}

function validatePages(pages: PageInfo[], label: string): void {
  if (pages.length > MAX_OPERATION_PAGES) {
    throw new Error(`${label} exceeds page budget`);
  }
  const ids: Set<string> = new Set<string>();
  for (let index: number = 0; index < pages.length; index++) {
    const page: PageInfo = pages[index];
    if (page.pageId.length === 0 || ids.has(page.pageId) || page.pageIndex !== index ||
      !Number.isSafeInteger(page.size) || page.size < PaperSize.A3 || page.size > PaperSize.TABLOID ||
      !Number.isSafeInteger(page.template) || page.template < PaperTemplate.PLAIN ||
      page.template > PaperTemplate.DECORATIVE || !Number.isSafeInteger(page.orientation) ||
      page.orientation < PageOrientation.PORTRAIT || page.orientation > PageOrientation.LANDSCAPE) {
      throw new Error(`${label} contains an invalid page`);
    }
    validatePageDimensions(page);
    ids.add(page.pageId);
  }
}

function validateSingleMembershipChange(before: PageInfo[], after: PageInfo[], inserting: boolean): void {
  const smaller: PageInfo[] = inserting ? before : after;
  const larger: PageInfo[] = inserting ? after : before;
  let changedIdentities: number = 0;
  for (const page of larger) {
    const match: PageInfo | null = findOptionalPage(smaller, page.pageId);
    if (match === null) {
      changedIdentities++;
    } else if (!samePageSettings(page, match)) {
      throw new Error('page membership mutation also changes page settings');
    }
  }
  if (changedIdentities !== 1 || !sameRelativeOrder(smaller, larger)) {
    throw new Error('page membership mutation is not a single ordered change');
  }
}

function sameRelativeOrder(smaller: PageInfo[], larger: PageInfo[]): boolean {
  const retained: string[] = [];
  const smallerIds: Set<string> = new Set<string>(pageIds(smaller));
  for (const page of larger) {
    if (smallerIds.has(page.pageId)) {
      retained.push(page.pageId);
    }
  }
  return sameStrings(retained, pageIds(smaller));
}

function sameMembers(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  const values: Set<string> = new Set<string>(left);
  for (const value of right) {
    if (!values.has(value)) {
      return false;
    }
  }
  return true;
}

function samePages(left: PageInfo[], right: PageInfo[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (!samePage(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

function samePage(left: PageInfo, right: PageInfo): boolean {
  return left.pageId === right.pageId && left.pageIndex === right.pageIndex &&
    samePageSettings(left, right);
}

function samePageSettings(left: PageInfo, right: PageInfo): boolean {
  return left.size === right.size && left.template === right.template &&
    left.orientation === right.orientation && left.widthMm === right.widthMm &&
    left.heightMm === right.heightMm;
}

function sameStrings(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}

function pageIds(pages: PageInfo[]): string[] {
  return pages.map((page: PageInfo): string => page.pageId);
}

function findPage(pages: PageInfo[], pageId: string): PageInfo {
  const page: PageInfo | null = findOptionalPage(pages, pageId);
  if (page === null) {
    throw new Error('page mutation references a missing page');
  }
  return page;
}

function findOptionalPage(pages: PageInfo[], pageId: string): PageInfo | null {
  for (const page of pages) {
    if (page.pageId === pageId) {
      return page;
    }
  }
  return null;
}

function clonePages(pages: PageInfo[]): PageInfo[] {
  return pages.map((page: PageInfo): PageInfo => ({
    pageId: page.pageId,
    pageIndex: page.pageIndex,
    size: page.size,
    template: page.template,
    orientation: page.orientation,
    widthMm: page.widthMm,
    heightMm: page.heightMm,
  }));
}

function encodePages(pages: PageInfo[]): EncodedPage[] {
  return pages.map((page: PageInfo): EncodedPage => ({
    value: page,
    pageId: encodeOperationString(page.pageId, 'page structure page ID'),
    width: encodeNumber(page.widthMm, 'page width'),
    height: encodeNumber(page.heightMm, 'page height'),
  }));
}

function encodeNumber(value: number, label: string): Uint8Array {
  if (!Number.isFinite(value)) {
    throw new Error(`${label} is invalid`);
  }
  return encodeOperationString(value.toString(), label);
}

function encodedPagesSize(pages: EncodedPage[]): number {
  let size: number = 4;
  for (const page of pages) {
    size += 4 + page.pageId.length + 8 + 4 + 4 + 4 +
      4 + page.width.length + 4 + page.height.length;
  }
  return size;
}

function writePages(writer: BinaryOpWriter, pages: EncodedPage[]): void {
  writer.writeUint32(pages.length);
  for (const page of pages) {
    writer.writeSizedBytes(page.pageId);
    writer.writeSafeInteger(page.value.pageIndex);
    writer.writeUint32(page.value.size);
    writer.writeUint32(page.value.template);
    writer.writeUint32(page.value.orientation);
    writer.writeSizedBytes(page.width);
    writer.writeSizedBytes(page.height);
  }
}

function readPages(reader: BinaryOpReader): PageInfo[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_PAGES) {
    throw new Error('page structure operation exceeds page budget');
  }
  const pages: PageInfo[] = [];
  for (let index: number = 0; index < count; index++) {
    pages.push({
      pageId: reader.readString(),
      pageIndex: reader.readSafeInteger(),
      size: reader.readUint32() as PaperSize,
      template: reader.readUint32() as PaperTemplate,
      orientation: reader.readUint32() as PageOrientation,
      widthMm: readNumber(reader, 'page width'),
      heightMm: readNumber(reader, 'page height'),
    });
  }
  return pages;
}

function readNumber(reader: BinaryOpReader, label: string): number {
  const encoded: string = reader.readString();
  const value: number = Number(encoded);
  if (!Number.isFinite(value) || value.toString() !== encoded) {
    throw new Error(`${label} is not a canonical finite number`);
  }
  return value;
}

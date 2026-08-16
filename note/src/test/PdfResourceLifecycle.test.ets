import { describe, it, expect } from '@ohos/hypium';
import {
  PdfNativeReleaseResult, releasePdfNativeResources,
} from '../main/ets/core/adaptation/PdfBackgroundLoader';

class FixturePdfPage {
  private events: string[];
  private shouldFail: boolean;

  constructor(events: string[], shouldFail: boolean = false) {
    this.events = events;
    this.shouldFail = shouldFail;
  }

  release(): void {
    this.events.push('page');
    if (this.shouldFail) {
      throw new Error('page release fixture failure');
    }
  }
}

class FixturePdfDocument {
  private events: string[];
  private shouldFail: boolean;

  constructor(events: string[], shouldFail: boolean = false) {
    this.events = events;
    this.shouldFail = shouldFail;
  }

  releaseDocument(): void {
    this.events.push('document');
    if (this.shouldFail) {
      throw new Error('document release fixture failure');
    }
  }
}

export default function pdfResourceLifecycleTest() {
  describe('PdfResourceLifecycle', () => {
    it('releases the page before its document', 0, () => {
      const events: string[] = [];
      const page: FixturePdfPage = new FixturePdfPage(events);
      const document: FixturePdfDocument = new FixturePdfDocument(events);
      const result: PdfNativeReleaseResult = releasePdfNativeResources(
        (): void => page.release(), (): void => document.releaseDocument());
      expect(events.join(',')).assertEqual('page,document');
      expect(result.pageError === null).assertTrue();
      expect(result.documentError === null).assertTrue();
    });

    it('releases a document even when no page was acquired', 0, () => {
      const events: string[] = [];
      const document: FixturePdfDocument = new FixturePdfDocument(events);
      const result: PdfNativeReleaseResult = releasePdfNativeResources(
        null, (): void => document.releaseDocument());
      expect(events.join(',')).assertEqual('document');
      expect(result.pageError === null).assertTrue();
      expect(result.documentError === null).assertTrue();
    });

    it('still releases the document after a page release failure', 0, () => {
      const events: string[] = [];
      const page: FixturePdfPage = new FixturePdfPage(events, true);
      const document: FixturePdfDocument = new FixturePdfDocument(events);
      const result: PdfNativeReleaseResult = releasePdfNativeResources(
        (): void => page.release(), (): void => document.releaseDocument());
      expect(events.join(',')).assertEqual('page,document');
      expect(result.pageError !== null).assertTrue();
      expect(result.documentError === null).assertTrue();
    });

    it('captures document release failure without throwing', 0, () => {
      const events: string[] = [];
      const page: FixturePdfPage = new FixturePdfPage(events);
      const document: FixturePdfDocument = new FixturePdfDocument(events, true);
      const result: PdfNativeReleaseResult = releasePdfNativeResources(
        (): void => page.release(), (): void => document.releaseDocument());
      expect(events.join(',')).assertEqual('page,document');
      expect(result.pageError === null).assertTrue();
      expect(result.documentError !== null).assertTrue();
    });
  });
}

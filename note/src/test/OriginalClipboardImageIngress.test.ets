import { describe, expect, it } from '@ohos/hypium';
import { image } from '@kit.ImageKit';
import {
  importOriginalClipboardImage,
  OriginalClipboardImageSource, resetOriginalClipboardImageReaderForTest,
  setOriginalClipboardImageReaderForTest,
} from '../main/ets/data/OriginalClipboardImageIngress';

class ClipboardImageSize {
  width: number = 0;
  height: number = 0;
}

class ClipboardImageInfo {
  size: ClipboardImageSize = new ClipboardImageSize();
}

class ClipboardImageProbe {
  released: boolean = false;

  async getImageInfo(): Promise<image.ImageInfo> {
    const info: ClipboardImageInfo = { size: { width: 12001, height: 1 } };
    return info as image.ImageInfo;
  }

  async release(): Promise<void> {
    this.released = true;
  }
}

function sourceFromProbe(probe: ClipboardImageProbe): OriginalClipboardImageSource {
  const pixelMap: image.PixelMap = probe as Object as image.PixelMap;
  return {
    pixelMap: pixelMap,
    release: async (): Promise<void> => {
      await probe.release();
    },
  };
}

export default function originalClipboardImageIngressTest() {
  describe('OriginalClipboardImageIngress', () => {
    it('rejects an empty clipboard without touching pixel maps', 0, async () => {
      setOriginalClipboardImageReaderForTest(
        async (): Promise<OriginalClipboardImageSource | null> => null);
      let failure = '';
      try {
        await importOriginalClipboardImage();
      } catch (e) {
        failure = (e as Error).message;
      }
      expect(failure).assertEqual('system pasteboard has no original clipboard image');
      resetOriginalClipboardImageReaderForTest();
    });

    it('rejects oversized clipboard pixels and releases the source', 0, async () => {
      const probe: ClipboardImageProbe = new ClipboardImageProbe();
      setOriginalClipboardImageReaderForTest(async (): Promise<OriginalClipboardImageSource> =>
        sourceFromProbe(probe));
      let failure = '';
      try {
        await importOriginalClipboardImage();
      } catch (e) {
        failure = (e as Error).message;
      }
      expect(failure).assertEqual('original clipboard image dimensions are invalid');
      expect(probe.released).assertTrue();
    });

    it('restores the production reader after an invalid probe', 0, async () => {
      const probe: ClipboardImageProbe = new ClipboardImageProbe();
      setOriginalClipboardImageReaderForTest(async (): Promise<OriginalClipboardImageSource> =>
        sourceFromProbe(probe));
      let failure = '';
      try {
        await importOriginalClipboardImage();
      } catch (e) {
        failure = (e as Error).message;
      }
      expect(failure).assertEqual('original clipboard image dimensions are invalid');
      expect(probe.released).assertTrue();
      resetOriginalClipboardImageReaderForTest();
    });
  });
}

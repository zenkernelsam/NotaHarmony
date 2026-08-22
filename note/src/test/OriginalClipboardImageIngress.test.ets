import { describe, expect, it } from '@ohos/hypium';
import { image } from '@kit.ImageKit';
import {
  addOriginalClipboardImageChangeListenerForTest,
  isOriginalClipboardImageAvailable,
  importOriginalClipboardImage,
  OriginalClipboardImageChangeListener,
  removeOriginalClipboardImageChangeListenerForTest,
  resetOriginalClipboardImageAvailabilityProbeForTest,
  resetOriginalClipboardImageReaderForTest,
  setOriginalClipboardImageAvailabilityProbeForTest,
  OriginalClipboardImageSource, setOriginalClipboardImageReaderForTest,
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
  scaled: boolean = false;
  requestedScaleX: number = 0;
  requestedScaleY: number = 0;
  width: number = 12001;
  height: number = 1;

  async getImageInfo(): Promise<image.ImageInfo> {
    const size: ClipboardImageSize = new ClipboardImageSize();
    size.width = this.width;
    size.height = this.height;
    const info: ClipboardImageInfo = new ClipboardImageInfo();
    info.size = size;
    return info as image.ImageInfo;
  }

  async release(): Promise<void> {
    this.released = true;
  }

  async createScaledPixelMap(x: number, y: number): Promise<image.PixelMap> {
    this.scaled = true;
    this.requestedScaleX = x;
    this.requestedScaleY = y;
    throw new Error('scaled clipboard probe stops before encoder');
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
    it('subscribes and removes the same pasteboard update listener', 0, () => {
      const added: OriginalClipboardImageChangeListener[] = [];
      const removed: OriginalClipboardImageChangeListener[] = [];
      let notified = false;
      const listener: OriginalClipboardImageChangeListener = (): void => {
        if (notified) {
          throw new Error('availability update stops after unsubscribe');
        }
        notified = true;
      };
      addOriginalClipboardImageChangeListenerForTest(listener);
      removeOriginalClipboardImageChangeListenerForTest(listener);
      expect(added.length).assertEqual(1);
      expect(removed.length).assertEqual(1);
      expect(removed[0]).assertEqual(added[0]);
    });
    it('reports only an available PixelMap MIME probe', 0, async () => {
      setOriginalClipboardImageAvailabilityProbeForTest(
        async (): Promise<boolean> => true);
      expect(await isOriginalClipboardImageAvailable()).assertTrue();

      setOriginalClipboardImageAvailabilityProbeForTest(
        async (): Promise<boolean> => false);
      expect(await isOriginalClipboardImageAvailable()).assertFalse();
      resetOriginalClipboardImageAvailabilityProbeForTest();
    });

    it('fails closed when the availability probe rejects', 0, async () => {
      setOriginalClipboardImageAvailabilityProbeForTest(
        async (): Promise<boolean> => {
          throw new Error('availability probe failed');
        });
      expect(await isOriginalClipboardImageAvailable()).assertFalse();
      resetOriginalClipboardImageAvailabilityProbeForTest();
    });

    it('restores the production availability probe', 0, async () => {
      setOriginalClipboardImageAvailabilityProbeForTest(
        async (): Promise<boolean> => true);
      resetOriginalClipboardImageAvailabilityProbeForTest();
      expect(await isOriginalClipboardImageAvailable()).assertFalse();
    });

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

    it('scales oversized clipboard pixels to the original 3000px adapter', 0, async () => {
      const probe: ClipboardImageProbe = new ClipboardImageProbe();
      setOriginalClipboardImageReaderForTest(async (): Promise<OriginalClipboardImageSource> =>
        sourceFromProbe(probe));
      let failure = '';
      try {
        await importOriginalClipboardImage();
      } catch (e) {
        failure = (e as Error).message;
      }
      expect(failure).assertEqual('scaled clipboard probe stops before encoder');
      expect(probe.scaled).assertTrue();
      expect(probe.requestedScaleX).assertEqual(3000 / 12001);
      expect(probe.requestedScaleY).assertEqual(3000);
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

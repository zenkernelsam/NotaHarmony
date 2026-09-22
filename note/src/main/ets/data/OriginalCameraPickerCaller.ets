// Original take-photo ingress (qc.java Take Photo menu item -> f35.java
// IMAGE_CAPTURE contract). The original launches the camera with an
// app-provided output URI then ingests that URI; HarmonyOS cameraPicker.pick
// returns the captured media URI directly, which feeds the shared
// importOriginalPhotos normalization/insert pipeline unchanged.
import { cameraPicker, camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import {
  importOriginalPhotos, OriginalPhotoIngressItem, isValidOriginalPhotoUri,
} from './OriginalPhotoIngress';

export interface OriginalCameraCaptureRequest {
  context: common.UIAbilityContext;
  cacheDirectory: string;
}

// Test seam mirroring OriginalPhotoPickerCaller's selector injection.
export type OriginalCameraUriCapturer =
  (context: common.UIAbilityContext) => Promise<string>;

let captureOriginalPhotoUri: OriginalCameraUriCapturer = captureWithHarmonyCameraPicker;

export function setOriginalCameraUriCapturerForTest(
  capturer: OriginalCameraUriCapturer): void {
  captureOriginalPhotoUri = capturer;
}

export function resetOriginalCameraUriCapturerForTest(): void {
  captureOriginalPhotoUri = captureWithHarmonyCameraPicker;
}

// cameraPicker is the system picker — no camera permission is required. The
// original passes EXTRA_OUTPUT + read/write grants to the camera app; the
// Harmony picker writes the capture to mediaLibrary and returns its URI.
async function captureWithHarmonyCameraPicker(
  context: common.UIAbilityContext): Promise<string> {
  const profile: cameraPicker.PickerProfile = {
    cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
  };
  const result: cameraPicker.PickerResult = await cameraPicker.pick(context,
    [cameraPicker.PickerMediaType.PHOTO], profile);
  // PickerResultCode 0 = success; a cancelled capture yields no usable URI.
  if (result.resultCode !== 0 || result.resultUri === '') {
    return '';
  }
  return result.resultUri;
}

// Returns [] on cancel (mirrors the photo picker's empty-selection contract —
// callers treat an empty list as a silent no-op).
export async function captureAndImportOriginalPhoto(
  request: OriginalCameraCaptureRequest): Promise<OriginalPhotoIngressItem[]> {
  const uri: string = await captureOriginalPhotoUri(request.context);
  if (uri === '') {
    return [];
  }
  if (!isValidOriginalPhotoUri(uri)) {
    throw new Error('original camera capture returned an unsupported image');
  }
  return importOriginalPhotos([uri], request.cacheDirectory);
}

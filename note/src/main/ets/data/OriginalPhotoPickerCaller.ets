import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import {
  importOriginalPhotos, OriginalPhotoIngressItem, validateOriginalPhotoSelection,
} from './OriginalPhotoIngress';

export interface OriginalPhotoSelectionRequest {
  context: common.UIAbilityContext;
  cacheDirectory: string;
}

export type OriginalPhotoUriListSelector = (context: common.UIAbilityContext) => Promise<string[]>;

export const ORIGINAL_PHOTO_PICKER_MAX_SELECTION: number = 500;

let selectOriginalPhotoUris: OriginalPhotoUriListSelector = selectWithHarmonyPhotoPicker;

export function setOriginalPhotoUriListSelectorForTest(
  selector: OriginalPhotoUriListSelector): void {
  selectOriginalPhotoUris = selector;
}

export function resetOriginalPhotoUriListSelectorForTest(): void {
  selectOriginalPhotoUris = selectWithHarmonyPhotoPicker;
}

async function selectWithHarmonyPhotoPicker(_context: common.UIAbilityContext): Promise<string[]> {
  const picker: photoAccessHelper.PhotoViewPicker =
    new photoAccessHelper.PhotoViewPicker();
  const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
  options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  options.maxSelectNumber = ORIGINAL_PHOTO_PICKER_MAX_SELECTION;
  const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
  if (!result.isOriginalPhoto) {
    throw new Error('photo picker returned a non-original image');
  }
  return Array.from(result.photoUris);
}

export async function pickAndImportOriginalPhotos(request: OriginalPhotoSelectionRequest):
  Promise<OriginalPhotoIngressItem[]> {
  const uris: string[] = await selectOriginalPhotoUris(request.context);
  if (!validateOriginalPhotoSelection(uris)) {
    throw new Error('original photo picker selection is empty or unsupported');
  }
  return importOriginalPhotos(uris, request.cacheDirectory);
}

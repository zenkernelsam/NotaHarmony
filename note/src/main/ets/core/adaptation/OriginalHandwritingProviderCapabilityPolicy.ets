// Static provider compatibility policy. A platform OCR capability is not an
// OriginalHandwritingRecognitionProvider merely because it can return text.
export const HARMONY_CORE_VISION_TEXT_RECOGNITION_SYSCAP: string =
  'SystemCapability.AI.OCR.TextRecognition';
export const HARMONY_CORE_VISION_DOCUMENTED_LANGUAGE_IDS: string[] =
  ['zh-CN', 'en', 'ja', 'ko', 'zh-TW'];

export enum OriginalHandwritingProviderCompatibilityReason {
  COMPATIBLE = 0,
  SYSTEM_CAPABILITY_UNAVAILABLE = 1,
  INPUT_IS_NOT_STROKE_NATIVE = 2,
  LANGUAGE_CANNOT_BE_LOCKED_PER_CALL = 3,
  LANGUAGE_COVERAGE_INCOMPLETE = 4,
}

export interface OriginalHandwritingProviderCapabilities {
  systemCapabilityAvailable: boolean;
  acceptsOrderedPointerStrokes: boolean;
  preservesForce: boolean;
  supportsPerCallLocaleCode: boolean;
  supportedLocaleCodes: string[];
  // Kept for evidence when a platform reports language IDs that cannot be
  // mapped to the original dc5.I locale-code contract.
  documentedLanguageIds: string[];
}

export interface OriginalHandwritingProviderCompatibility {
  compatible: boolean;
  reason: OriginalHandwritingProviderCompatibilityReason;
}

export function evaluateOriginalHandwritingProviderCompatibility(
  capabilities: OriginalHandwritingProviderCapabilities):
  OriginalHandwritingProviderCompatibility {
  if (!capabilities.systemCapabilityAvailable) {
    return incompatible(OriginalHandwritingProviderCompatibilityReason.SYSTEM_CAPABILITY_UNAVAILABLE);
  }
  if (!capabilities.acceptsOrderedPointerStrokes || !capabilities.preservesForce) {
    return incompatible(OriginalHandwritingProviderCompatibilityReason.INPUT_IS_NOT_STROKE_NATIVE);
  }
  if (!capabilities.supportsPerCallLocaleCode) {
    return incompatible(
      OriginalHandwritingProviderCompatibilityReason.LANGUAGE_CANNOT_BE_LOCKED_PER_CALL);
  }
  if (!supportsEveryOriginalLocale(capabilities.supportedLocaleCodes)) {
    return incompatible(OriginalHandwritingProviderCompatibilityReason.LANGUAGE_COVERAGE_INCOMPLETE);
  }
  return {
    compatible: true,
    reason: OriginalHandwritingProviderCompatibilityReason.COMPATIBLE,
  };
}

export function harmonyCoreVisionTextRecognitionCapabilities(
  systemCapabilityAvailable: boolean): OriginalHandwritingProviderCapabilities {
  return {
    systemCapabilityAvailable: systemCapabilityAvailable,
    // CoreVision consumes an RGBA_8888 PixelMap. It has no pointer lifecycle
    // or pressure contract, and its configuration only controls orientation.
    acceptsOrderedPointerStrokes: false,
    preservesForce: false,
    supportsPerCallLocaleCode: false,
    supportedLocaleCodes: [],
    documentedLanguageIds: HARMONY_CORE_VISION_DOCUMENTED_LANGUAGE_IDS,
  };
}

// A production caller may pass the result of the platform `canIUse(syscap)`
// probe here. Keeping the probe injected avoids importing an internal global
// into the pure policy module and makes the capability decision replayable.
export function evaluateHarmonyCoreVisionTextRecognitionCompatibility(
  capabilityProbe: (syscap: string) => boolean): OriginalHandwritingProviderCompatibility {
  return evaluateOriginalHandwritingProviderCompatibility(
    harmonyCoreVisionTextRecognitionCapabilities(
      capabilityProbe(HARMONY_CORE_VISION_TEXT_RECOGNITION_SYSCAP)));
}

export function canUseHarmonyCoreVisionAsOriginalHandwritingProvider(
  systemCapabilityAvailable: boolean): boolean {
  return evaluateOriginalHandwritingProviderCompatibility(
    harmonyCoreVisionTextRecognitionCapabilities(systemCapabilityAvailable)).compatible;
}

function supportsEveryOriginalLocale(values: string[]): boolean {
  const required: string[] = [
    'de_DE', 'en_US', 'es_ES', 'fr_FR', 'it_IT', 'ja_JP', 'ko_KR', 'nl_NL',
    'no_NO', 'pt_BR', 'ru_RU', 'tr_TR', 'zh_CN', 'zh_TW', 'th_TH', 'fil_PH',
    'id_ID', 'ms_MY', 'pl_PL', 'sv_SE', 'uk_UA', 'vi_VN', 'da_DK',
  ];
  const available: Set<string> = new Set<string>();
  for (const value of values) {
    available.add(value);
  }
  for (const value of required) {
    if (!available.has(value)) {
      return false;
    }
  }
  return true;
}

function incompatible(reason: OriginalHandwritingProviderCompatibilityReason):
  OriginalHandwritingProviderCompatibility {
  return { compatible: false, reason: reason };
}

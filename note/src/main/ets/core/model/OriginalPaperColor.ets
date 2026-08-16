import { PagePaperBackground } from './NoteTypes';
import {
  OriginalRgbaColor, packOriginalArgb, unpackOriginalArgb,
} from './OriginalPaperSettings';

export interface OriginalHsvColor {
  hue: number;
  saturation: number;
  value: number;
}

export interface OriginalPaperRenderStyle {
  backgroundColor: string;
  lineColor: string;
  invertLegacyTexture: boolean;
}

export const ORIGINAL_LEGACY_PAPER_PICKER_INDICES: number[] = [13, 1, 2, 15, 7, 6];

// Original 1.0.3 iq0/n7j picker order and swatch colors. These colors identify the
// choices in the picker; the canvas itself uses the corresponding 1024x1024 WebP.
export function originalLegacyPaperPickerSwatchArgb(legacyPaperIndex: number): number | null {
  switch (legacyPaperIndex) {
    case 13:
      return packOriginalArgb(255, 255, 255);
    case 1:
      return packOriginalArgb(251, 248, 244);
    case 2:
      return packOriginalArgb(252, 246, 207);
    case 15:
      return packOriginalArgb(41, 41, 41);
    case 7:
      return packOriginalArgb(225, 232, 236);
    case 6:
      return packOriginalArgb(231, 221, 180);
    default:
      return null;
  }
}

// Original m3a maps only 1..15 to bundled legacy bitmaps. Wire values outside this
// range remain readable but deliberately have no fabricated replacement texture.
export function originalLegacyPaperResourceName(legacyPaperIndex: number): string | null {
  switch (legacyPaperIndex) {
    case 1:
      return 'core_paper__paper01.webp';
    case 2:
      return 'core_paper__paper02.webp';
    case 3:
      return 'core_paper__paper03.webp';
    case 4:
      return 'core_paper__paper04.webp';
    case 5:
      return 'core_paper__paper05.webp';
    case 6:
      return 'core_paper__paper06.webp';
    case 7:
      return 'core_paper__paper07.webp';
    case 8:
      return 'core_paper__paper08.webp';
    case 9:
      return 'core_paper__paper09.webp';
    case 10:
      return 'core_paper__paper10.webp';
    case 11:
      return 'core_paper__paper11.webp';
    case 12:
      return 'core_paper__paper12.webp';
    case 13:
      return 'core_paper__paper13.webp';
    case 14:
      return 'core_paper__paper14.webp';
    case 15:
      return 'core_paper__paper15.webp';
    default:
      return null;
  }
}

export function originalArgbCssColor(value: number): string {
  return rgbaCss(unpackOriginalArgb(value));
}

export function originalHsvFromArgb(value: number): OriginalHsvColor {
  const color: OriginalRgbaColor = unpackOriginalArgb(value);
  const red: number = color.red / 255.0;
  const green: number = color.green / 255.0;
  const blue: number = color.blue / 255.0;
  const maximum: number = Math.max(red, green, blue);
  const minimum: number = Math.min(red, green, blue);
  const delta: number = maximum - minimum;
  let hue: number = 0;
  if (delta > 0) {
    if (maximum === red) {
      hue = 60 * (((green - blue) / delta) % 6);
    } else if (maximum === green) {
      hue = 60 * (((blue - red) / delta) + 2);
    } else {
      hue = 60 * (((red - green) / delta) + 4);
    }
  }
  if (hue < 0) {
    hue += 360;
  }
  return {
    hue: hue,
    saturation: maximum === 0 ? 0 : delta / maximum,
    value: maximum,
  };
}

// ua5 opens rw1 without alpha controls. Existing alpha is preserved while merely
// reading a draft, but any newly edited HSV value is therefore written opaque.
export function originalOpaqueArgbFromHsv(hue: number, saturation: number,
  value: number): number {
  if (!Number.isFinite(hue) || !Number.isFinite(saturation) || !Number.isFinite(value) ||
    hue < 0 || hue > 360 || saturation < 0 || saturation > 1 || value < 0 || value > 1) {
    throw new Error('original paper HSV color is invalid');
  }
  const rgb: OriginalRgbaColor = hsvToRgba(hue === 360 ? 0 : hue, saturation, value, 255);
  return packOriginalArgb(rgb.red, rgb.green, rgb.blue, rgb.alpha);
}

export function originalPaperRenderStyle(paper: PagePaperBackground | null,
  fallbackBackground: string, fallbackLine: string, darkMode: boolean): OriginalPaperRenderStyle {
  if (paper === null) {
    return {
      backgroundColor: fallbackBackground,
      lineColor: fallbackLine,
      invertLegacyTexture: false,
    };
  }
  const explicit: OriginalRgbaColor | null = explicitPaperColor(paper);
  let background: OriginalRgbaColor = explicit === null
    ? { red: 255, green: 255, blue: 255, alpha: 255 } : explicit;
  let line: OriginalRgbaColor | null = originalPaperLineColor(paper);
  const invert: boolean = darkMode && !isOriginalPaperDark(paper);
  if (invert) {
    background = invertRgb(background);
    if (line !== null) {
      line = invertRgb(line);
    }
  }
  return {
    backgroundColor: rgbaCss(background),
    lineColor: line === null ? fallbackLine : rgbaCss(line),
    invertLegacyTexture: invert,
  };
}

export function originalPaperPickerPreviewColor(backgroundColor: number | null,
  legacyPaperIndex: number | null, fallback: string, darkMode: boolean): string {
  let preview: OriginalRgbaColor | null = backgroundColor === null
    ? null : unpackOriginalArgb(backgroundColor);
  if (preview === null && legacyPaperIndex !== null) {
    const swatch: number | null = originalLegacyPaperPickerSwatchArgb(legacyPaperIndex);
    preview = swatch === null ? null : unpackOriginalArgb(swatch);
  }
  if (preview === null) {
    return fallback;
  }
  const paper: PagePaperBackground = {
    flair: null, flairSpacingPt: null, flairBleeds: null, flairCentered: null,
    colorR: backgroundColor === null ? null : preview.red,
    colorG: backgroundColor === null ? null : preview.green,
    colorB: backgroundColor === null ? null : preview.blue,
    colorA: backgroundColor === null ? null : preview.alpha,
    legacyPaperIndex: legacyPaperIndex,
  };
  return darkMode && !isOriginalPaperDark(paper) ? rgbaCss(invertRgb(preview)) : rgbaCss(preview);
}

export function originalPaperPickerPreviewLineColor(backgroundColor: number | null,
  legacyPaperIndex: number | null, fallback: string, darkMode: boolean): string {
  const color: OriginalRgbaColor | null = backgroundColor === null
    ? null : unpackOriginalArgb(backgroundColor);
  const paper: PagePaperBackground = {
    flair: null, flairSpacingPt: null, flairBleeds: null, flairCentered: null,
    colorR: color === null ? null : color.red,
    colorG: color === null ? null : color.green,
    colorB: color === null ? null : color.blue,
    colorA: color === null ? null : color.alpha,
    legacyPaperIndex: legacyPaperIndex,
  };
  return originalPaperRenderStyle(paper, '#FFFFFFFF', fallback, darkMode).lineColor;
}

function originalPaperLineColor(paper: PagePaperBackground): OriginalRgbaColor | null {
  if (paper.legacyPaperIndex !== null) {
    return originalLegacyPaperLineColor(paper.legacyPaperIndex);
  }
  // u3a.a(k3a) substitutes m09.e (opaque white) when the paper has no explicit
  // color, then applies the same custom-color lookup/contrast algorithm.
  const explicit: OriginalRgbaColor | null = explicitPaperColor(paper);
  const background: OriginalRgbaColor = explicit === null
    ? { red: 255, green: 255, blue: 255, alpha: 255 } : explicit;
  const mapped: OriginalRgbaColor | null = originalMappedCustomLineColor(background);
  if (mapped !== null) {
    return mapped;
  }
  const luminance: number = (background.red * 299 + background.green * 587 +
    background.blue * 114) / (255000.0);
  const hsv: OriginalHsvColor = originalHsvFromArgb(packOriginalArgb(
    background.red, background.green, background.blue, background.alpha));
  return hsvToRgba(hsv.hue, hsv.saturation, luminance > 0.25 ? 0.2 : 0.95,
    luminance > 0.25 ? 51 : background.alpha);
}

function originalLegacyPaperLineColor(legacyPaperIndex: number): OriginalRgbaColor | null {
  switch (legacyPaperIndex) {
    case 0:
    case 1:
      return opaque(194, 192, 183);
    case 2:
    case 6:
      return opaque(148, 142, 121);
    case 3:
    case 7:
      return opaque(110, 151, 189);
    case 4:
      return opaque(113, 189, 135);
    case 5:
      return opaque(189, 93, 93);
    case 8:
      return opaque(64, 64, 64);
    case 9:
      return opaque(150, 134, 122);
    case 10:
      return opaque(88, 52, 92);
    case 11:
      return opaque(173, 125, 53);
    case 12:
      return opaque(108, 106, 116);
    case 13:
      return opaque(163, 183, 211);
    case 14:
      return opaque(152, 174, 186);
    case 15:
      return opaque(90, 90, 90);
    default:
      // u3a.a logs an invalid legacy index and returns iu1.b (opaque black).
      return opaque(0, 0, 0);
  }
}

function originalMappedCustomLineColor(background: OriginalRgbaColor): OriginalRgbaColor | null {
  if (background.alpha !== 255) {
    return null;
  }
  const key: string = `${background.red},${background.green},${background.blue}`;
  switch (key) {
    case '255,255,0': return opaque(189, 169, 0);
    case '250,157,0': return opaque(156, 97, 0);
    case '237,54,36': return opaque(125, 11, 0);
    case '255,0,212': return opaque(141, 0, 117);
    case '169,255,23': return opaque(105, 166, 0);
    case '96,186,70': return opaque(31, 130, 3);
    case '164,0,199': return opaque(89, 0, 107);
    case '98,45,144': return opaque(57, 0, 106);
    case '0,115,59': return opaque(0, 74, 38);
    case '0,111,255': return opaque(0, 75, 174);
    case '23,73,179': return opaque(0, 40, 121);
    case '18,3,119': return opaque(105, 84, 245);
    case '255,255,255': return opaque(187, 187, 187);
    case '150,150,150': return opaque(80, 80, 80);
    case '0,0,0': return opaque(129, 129, 129);
    case '148,102,53': return opaque(65, 34, 0);
    case '241,196,15': return opaque(163, 131, 0);
    case '203,103,14': return opaque(138, 64, 0);
    case '226,106,106': return opaque(151, 18, 17);
    case '181,21,21': return opaque(122, 0, 0);
    case '239,95,51': return opaque(167, 39, 0);
    case '207,54,108': return opaque(90, 0, 32);
    case '47,218,119': return opaque(55, 144, 93);
    case '25,176,146': return opaque(0, 112, 90);
    case '157,187,216': return opaque(93, 118, 144);
    case '20,199,222': return opaque(17, 143, 159);
    case '52,152,219': return opaque(22, 90, 135);
    case '68,79,173': return opaque(20, 29, 109);
    case '199,195,189': return opaque(109, 108, 106);
    case '81,92,93': return opaque(44, 44, 44);
    case '176,156,255': return opaque(76, 58, 143);
    case '140,84,208': return opaque(51, 15, 95);
    default: return null;
  }
}

function isOriginalPaperDark(paper: PagePaperBackground): boolean {
  const legacy: number | null = paper.legacyPaperIndex;
  if (legacy === 8 || legacy === 11 || legacy === 12 || legacy === 14 || legacy === 15) {
    return true;
  }
  const color: OriginalRgbaColor | null = explicitPaperColor(paper);
  return color !== null && (color.red + color.green + color.blue) / (3 * 255.0) <= 0.5;
}

function explicitPaperColor(paper: PagePaperBackground): OriginalRgbaColor | null {
  if (paper.colorR === null || paper.colorG === null || paper.colorB === null ||
    paper.colorA === null) {
    return null;
  }
  return {
    red: paper.colorR,
    green: paper.colorG,
    blue: paper.colorB,
    alpha: paper.colorA,
  };
}

function hsvToRgba(hue: number, saturation: number, value: number,
  alpha: number): OriginalRgbaColor {
  const chroma: number = value * saturation;
  const segment: number = hue / 60;
  const secondary: number = chroma * (1 - Math.abs((segment % 2) - 1));
  let red: number = 0;
  let green: number = 0;
  let blue: number = 0;
  if (segment < 1) {
    red = chroma; green = secondary;
  } else if (segment < 2) {
    red = secondary; green = chroma;
  } else if (segment < 3) {
    green = chroma; blue = secondary;
  } else if (segment < 4) {
    green = secondary; blue = chroma;
  } else if (segment < 5) {
    red = secondary; blue = chroma;
  } else {
    red = chroma; blue = secondary;
  }
  const offset: number = value - chroma;
  return {
    red: Math.round((red + offset) * 255),
    green: Math.round((green + offset) * 255),
    blue: Math.round((blue + offset) * 255),
    alpha: Math.round(alpha),
  };
}

function opaque(red: number, green: number, blue: number): OriginalRgbaColor {
  return { red: red, green: green, blue: blue, alpha: 255 };
}

function invertRgb(color: OriginalRgbaColor): OriginalRgbaColor {
  return {
    red: 255 - color.red,
    green: 255 - color.green,
    blue: 255 - color.blue,
    alpha: color.alpha,
  };
}

function rgbaCss(color: OriginalRgbaColor): string {
  return `rgba(${color.red},${color.green},${color.blue},${color.alpha / 255.0})`;
}

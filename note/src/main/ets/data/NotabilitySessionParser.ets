// T-032 Notability Session.plist / metadata.plist 解析器
// 纯 ArkTS，无平台依赖。基于 test_notes/OP-AMP.note 逆向确认，详见
// docs/migration/reports/T-032-完成.md。
//
// ── Session.plist 对象图（实测 OP-AMP.note，archiver=GLKeyedArchiver，$top 键为 "$0"）──
// NoteTakingSession
//   ├ name / packagePath ................ "OP-AMP"
//   ├ creationDate ...................... NSDate
//   ├ sessionFormatVersion .............. 9
//   ├ NBNoteTakingSessionDocumentPaperLayoutModelKey → Notability.NoteDocumentPaperLayoutModel
//   │    └ documentPaperAttributes → GLModel.PaperAttributes
//   │         { paperSize:"letter", paperOrientation:"portrait",
//   │           paperSizingBehavior:"lockedWidth:716.8:iPad",
//   │           paperIdentifier:"Legacy:13", lineStyle2:"Lines:false:true:0.393701" }
//   └ richText → FormattedString
//        ├ reflowState → NBReflowStateLocked { pageWidthInDocumentCoordsKey: 716.8 }
//        └ "Handwriting Overlay" → HandwritingObject
//             └ SpatialHash → InkedSpatialHash   ← 全部笔画都在这里
//
// ── InkedSpatialHash 的并列数组（SoA）布局 ──
// 计数：numcurves=NC, numpoints=NP, numfractionalwidths=NF
//   每条曲线是一条三次贝塞尔链：numpoints_i = 3*k_i + 1（k_i 段），锚点数 = k_i + 1
//   因此 Σnumpoints_i = NP，Σ(k_i+1) = NF（OP-AMP 实测 31242 / 11316，完全吻合）
//
//   按曲线索引(NC)：curvesnumpoints u32 | curveswidth f32 | curvescolors RGBA×4B
//                   curvesstyles u8 | curveUUIDs 16B | options u64
//   按点索引(NP)：  curvespoints f32×2 (x,y)   ← 中心线坐标
//   按锚点索引(NF)：curvesfractionalwidths f32 | curvesforces f32
//                   curvesaltitudeangles f32 | curvesazimuthunitvector f32×2
//
//   curveswidth 是**完整线宽**（非半宽）：实测半宽 0.4667 正是中心线外框与
//   index.plist pageContentOrigin 的差值，见下方 FALLBACK_PAGE_ASPECT 注释。
//
//   ⚠ 全部为**小端** IEEE-754 / 无符号整数（iOS 内存直存），与 plist 容器的大端相反。
//
// ── InkedSpatialHash.shapes：形状识别层（**内嵌的另一个 bplist00**）──
// 不是归档，是一个普通 binary plist，三个并列数组：
//   shapes[]  每项 { appearance{style,strokeColor{rgba:[r,g,b,a] 0~1},strokeWidth},
//                    uuid(16B), options, rect:[[x,y],[w,h]],
//                    + 按 kind 不同的几何字段 }
//   kinds[]   'line' | 'circle' | 'rectangle'（实测 96/3/1）
//   indices[] 严格递增且唯一，值域 0..numcurves —— 形状在曲线绘制序列中的**插入位**
//             （最大值恰等于 numcurves=1353，只有"插在第 i 条曲线之前"这一解读能成立）
//   几何：line → startPt/endPt；rectangle → points[] + isClosed；
//         circle → rotatedRect.corners[4]，椭圆内切于该平行四边形
//   rect 恒等于几何外框外扩半线宽（第三次印证半宽语义）
//   ⚠ 形状 UUID 与 curveUUIDs **无交集**，即形状是曲线之外的独立内容，
//     只画曲线会丢掉全部导线/圆/框（本样本 100 个）。

import { float32From, uint32LE, PlistValue, PlistType, BinaryPlistParser,
  PlistParseResult } from './BinaryPlistParser';
import { NSKeyedArchiverDecoder, ArchiveNode, ArchiveDecodeResult } from './NSKeyedArchiverDecoder';
import { Point2D, Rect2D, CubicSegment } from '../core/model/GeometryTypes';
import { StrokeElementData, StrokePathPoint, RenderSpec, InkStyle } from '../core/model/StrokeTypes';
import { ElementType, ShapeArrowHead, ShapeElement } from '../core/model/ElementTypes';
import { recomputeShapeBounds } from '../core/model/ShapeGeometry';
import { PageElementKind, PageElementRef } from '../core/model/PageElementOrder';

// iPad lockedWidth 版式下的页面宽高比。
// 依据一：OP-AMP.note 的 thumb12x.png 为 576×756，比值恰为 1.3125。
// 依据二：取 pageHeight = 716.8 × 1.3125 = 940.8 把点坐标折算到页内后，三页的
//   (minX, minY) 与 HandwritingIndex/index.plist 里各页 pageContentOrigin 的差值
//   在 6 个数上全部精确等于 +0.4667 = curveswidth/2 —— 即索引记录的是**含半线宽的
//   渲染外框**，而 curvespoints 是中心线。页高若有偏差，第 2、3 页的 dy 会立刻发散。
//   （其他候选页高 927.62 / 936 / 955.73 均相差 13~32，全部排除。）
// ⚠ 假设：仅有一份样本（letter / portrait / iPad）。横版、A4、非 iPad 版式未验证。
// 因此优先用缩略图实测比例，此常量仅作兜底。
const FALLBACK_PAGE_ASPECT: number = 1.3125;

// 导入目标画布宽度（vp）。内部笔画目前以设备 vp 存储（见 NoteCanvasView，画布 100%×100%），
// 没有与设备无关的页面坐标系，所以导入必须选一个参考宽度做缩放。
// ⚠ 这是当前架构的既有局限，不是本任务引入的；详见完成报告"遗留问题"。
export const DEFAULT_TARGET_PAGE_WIDTH_VP: number = 360;

// 实测到的笔画样式值。OP-AMP.note 中 1353 条曲线全部为 3（普通笔）。
// 其余取值（高亮笔/铅笔等）无样本，遇到时记录 warning 并退化为定宽笔。
const STYLE_PEN_OBSERVED: number = 3;
const ATTRIBUTE_TOLERANCE: number = 0.0001;

export interface NotabilityCurveFidelity {
  widthUnmapped: boolean;
  forceUnmapped: boolean;
  orientationUnmapped: boolean;
  styleUnmapped: boolean;
  degraded: boolean;
}

export function assessNotabilityCurveFidelity(style: number, fractionalWidths: number[],
  forces: number[], altitudeAngles: number[], azimuthX: number[], azimuthY: number[]): NotabilityCurveFidelity {
  const widthUnmapped: boolean = hasAttributeVariation(fractionalWidths, 1.0);
  const forceUnmapped: boolean = hasAttributeVariation(forces, 1.0);
  const orientationUnmapped: boolean = hasAttributeVariation(altitudeAngles, Math.PI / 2) ||
    hasAttributeVariation(azimuthX, 1.0) || hasAttributeVariation(azimuthY, 0.0);
  const styleUnmapped: boolean = style !== STYLE_PEN_OBSERVED;
  return {
    widthUnmapped: widthUnmapped,
    forceUnmapped: forceUnmapped,
    orientationUnmapped: orientationUnmapped,
    styleUnmapped: styleUnmapped,
    degraded: widthUnmapped || forceUnmapped || orientationUnmapped || styleUnmapped,
  };
}

function hasAttributeVariation(values: number[], baseline: number): boolean {
  for (let i: number = 0; i < values.length; i++) {
    if (!Number.isFinite(values[i]) || Math.abs(values[i] - baseline) > ATTRIBUTE_TOLERANCE) {
      return true;
    }
  }
  return false;
}

function emptyRect(): Rect2D {
  return { left: 0, top: 0, right: 0, bottom: 0 };
}

function samePoint(left: Point2D, right: Point2D): boolean {
  return Math.abs(left.x - right.x) <= 0.000001 && Math.abs(left.y - right.y) <= 0.000001;
}

// ============================ 输出模型 ============================

export interface NotabilityCurve {
  index: number;
  uuid: string;               // 32 位十六进制
  colorArgb: number;          // 有符号 ARGB
  width: number;              // 文档坐标下的笔宽
  style: number;              // 原始样式字节
  options: number;            // 原始 options（实测恒为 0，语义未知）
  points: Point2D[];          // 3k+1 个：锚点与控制点交替
  fractionalWidths: number[]; // k+1
  forces: number[];           // k+1，[0,1]
  altitudeAngles: number[];   // k+1，弧度
  azimuthX: number[];         // k+1
  azimuthY: number[];         // k+1
  bounds: Rect2D;
  pageIndex: number;
}

// 形状识别层的一个形状（已归一化为折线/贝塞尔，便于直接渲染）
export interface NotabilityShape {
  index: number;
  uuid: string;
  kind: string;             // 'line' | 'circle' | 'rectangle'
  zIndex: number;           // indices[i]：插在第 zIndex 条曲线之前
  colorArgb: number;
  width: number;
  style: number;
  options: number;
  anchors: Point2D[];       // 折线顶点（circle 为 4 个象限锚点）
  cubics: CubicSegment[];   // circle 为 4 段椭圆弧；line/rectangle 为空
  isClosed: boolean;
  bounds: Rect2D;
  pageIndex: number;
}

export interface NotabilityPaper {
  paperSize: string;
  paperOrientation: string;
  paperIdentifier: string;
  lineStyle: string;
  sizingBehavior: string;
  layoutDevice: string;
}

export interface NotabilityContentCount {
  found: number;
  recovered: number;
  degraded: number;
  unquantifiedLoss: boolean;
}

export interface NotabilityContentInventory {
  handwriting: NotabilityContentCount;
  shapes: NotabilityContentCount;
  textCharacters: NotabilityContentCount;
  media: NotabilityContentCount;
  pdf: NotabilityContentCount;
  audio: NotabilityContentCount;
}

export function summarizeNotabilityContentLoss(inventory: NotabilityContentInventory): string[] {
  const details: string[] = [];
  appendContentLoss(details, '手写笔迹', '条', inventory.handwriting);
  appendContentLoss(details, '识别形状', '个', inventory.shapes);
  appendContentLoss(details, '键入文本', '字符', inventory.textCharacters);
  appendContentLoss(details, '图片/附件', '项', inventory.media);
  appendContentLoss(details, 'PDF 底稿', '项', inventory.pdf);
  appendContentLoss(details, '录音', '项', inventory.audio);
  return details;
}

export function resolveNotabilityPageCount(derivedFromContent: number, pageCountHint: number): number {
  return Math.max(1, derivedFromContent, pageCountHint);
}

export interface NotabilitySession {
  ok: boolean;
  error: string;
  noteName: string;
  creationMillis: number;
  sessionFormatVersion: number;
  bundleVersion: string;
  handwritingLanguage: string;
  paper: NotabilityPaper;
  pageWidthDoc: number;
  pageHeightDoc: number;
  pageCount: number;
  curves: NotabilityCurve[];
  shapes: NotabilityShape[];
  totalPoints: number;
  inventory: NotabilityContentInventory;
  warnings: string[];
  missingAssets: string[];
  unparsed: string[];
  structureLog: string;
}

export interface NotabilityMetadata {
  ok: boolean;
  error: string;
  noteName: string;
  uuid: string;
  createdMillis: number;
  modifiedMillis: number;
  hasRecording: boolean;
  subject: string;
  fieldsFound: number;
  fieldsRecovered: number;
  warnings: string[];
}

// 每页转换结果。原版 shapes 必须保持语义元素身份及与曲线交错的层序。
export interface NotabilityPageElements {
  pageIndex: number;
  strokes: StrokeElementData[];
  shapes: ShapeElement[];
  elementOrder: PageElementRef[];
}

// ============================ 元数据解析 ============================

export class NotabilityMetadataParser {
  // 解析 metadata.plist（NSKeyedArchiver / SessionInfo）
  static parse(data: Uint8Array): NotabilityMetadata {
    const out: NotabilityMetadata = {
      ok: false, error: '', noteName: '', uuid: '',
      createdMillis: 0, modifiedMillis: 0, hasRecording: false, subject: '',
      fieldsFound: 0, fieldsRecovered: 0, warnings: [],
    };
    const parsed: PlistParseResult = BinaryPlistParser.parse(data);
    if (parsed.value === null) {
      out.error = `metadata.plist 解析失败：${parsed.error}`;
      return out;
    }
    appendUniqueAll(out.warnings, parsed.warnings);
    const decoded: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(parsed.value);
    if (decoded.decoder === null) {
      out.error = `metadata.plist 归档解码失败：${decoded.error}`;
      return out;
    }
    appendUniqueAll(out.warnings, decoded.warnings);
    const root: ArchiveNode | null = decoded.decoder.rootNode();
    if (root === null) {
      out.error = 'metadata.plist 缺少根对象';
      return out;
    }
    out.noteName = root.stringOf('noteName', '');
    out.uuid = root.stringOf('uuidKey', '');
    out.subject = root.stringOf('noteSubject', '');
    out.createdMillis = root.dateMillisOf('noteCreationDateKey', 0);
    out.modifiedMillis = root.dateMillisOf('noteModifiedDateKey', 0);
    out.hasRecording = root.boolOf('noteHasRecordingKey', false);
    const metadataKeys: string[] = [
      'noteName', 'uuidKey', 'noteSubject', 'noteCreationDateKey', 'noteModifiedDateKey',
      'noteHasRecordingKey',
    ];
    for (let i: number = 0; i < metadataKeys.length; i++) {
      if (root.has(metadataKeys[i])) {
        out.fieldsFound++;
      }
    }
    const criticalRecovered: number = (out.noteName.length > 0 ? 1 : 0) +
      (out.uuid.length > 0 ? 1 : 0) + (out.subject.length > 0 ? 1 : 0) +
      (out.createdMillis > 0 ? 1 : 0) + (out.modifiedMillis > 0 ? 1 : 0);
    if (out.fieldsFound === 0 || criticalRecovered === 0) {
      out.error = 'metadata.plist 不含可恢复的标题、UUID、主题或时间字段';
      return out;
    }
    // 字段存在且对象图已成功解码即视为恢复；空 subject/title 可以是合法用户数据。
    out.fieldsRecovered = out.fieldsFound;
    out.ok = true;
    return out;
  }
}

// ============================ Session 解析 ============================

export class NotabilitySessionParser {
  // 解析 Session.plist。
  // thumbAspect：缩略图高/宽，>0 时用于推导页高（优先于兜底常量）
  // pageCountHint：HandwritingIndex/index.plist 的页数，>0 时用于交叉校验
  static parse(data: Uint8Array, thumbAspect: number, pageCountHint: number): NotabilitySession {
    const out: NotabilitySession = {
      ok: false, error: '', noteName: '', creationMillis: 0, sessionFormatVersion: 0,
      bundleVersion: '', handwritingLanguage: '',
      paper: {
        paperSize: '', paperOrientation: '', paperIdentifier: '',
        lineStyle: '', sizingBehavior: '', layoutDevice: '',
      },
      pageWidthDoc: 0, pageHeightDoc: 0, pageCount: 0,
      curves: [], shapes: [], totalPoints: 0, inventory: createNotabilityContentInventory(),
      warnings: [], missingAssets: [], unparsed: [], structureLog: '',
    };

    const parsed: PlistParseResult = BinaryPlistParser.parse(data);
    if (parsed.value === null) {
      out.error = `Session.plist 解析失败：${parsed.error}`;
      return out;
    }
    for (let i: number = 0; i < parsed.warnings.length; i++) {
      out.warnings.push(parsed.warnings[i]);
    }
    const decoded: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(parsed.value);
    if (decoded.decoder === null) {
      out.error = `Session.plist 归档解码失败：${decoded.error}`;
      return out;
    }
    const decoder: NSKeyedArchiverDecoder = decoded.decoder;
    appendUniqueAll(out.warnings, decoded.warnings);
    out.structureLog = decoder.describeGraph(8, 24);

    const root: ArchiveNode | null = decoder.rootNode();
    if (root === null) {
      out.error = 'Session.plist 缺少根对象';
      return out;
    }

    // --- 会话级字段 ---
    out.noteName = root.stringOf('name', '');
    out.creationMillis = root.dateMillisOf('creationDate', 0);
    out.sessionFormatVersion = root.numberOf('sessionFormatVersion', 0);
    out.bundleVersion = root.stringOf('NBNoteTakingSessionBundleVersionNumberKey', '');
    out.handwritingLanguage = root.stringOf('NBNoteTakingSessionHandwritingLanguageKey', '');

    // --- 纸张属性 ---
    const layoutModel: ArchiveNode | null = root.node('NBNoteTakingSessionDocumentPaperLayoutModelKey');
    if (layoutModel !== null) {
      const attrs: ArchiveNode | null = layoutModel.node('documentPaperAttributes');
      if (attrs !== null) {
        out.paper.paperSize = attrs.stringOf('paperSize', '');
        out.paper.paperOrientation = attrs.stringOf('paperOrientation', '');
        out.paper.paperIdentifier = attrs.stringOf('paperIdentifier', '');
        out.paper.lineStyle = attrs.stringOf('lineStyle2', '');
        out.paper.sizingBehavior = attrs.stringOf('paperSizingBehavior', '');
      }
    }

    // --- 页宽（reflowState）---
    const richText: ArchiveNode | null = root.node('richText');
    if (richText === null) {
      out.error = 'Session.plist 缺少 richText（FormattedString）';
      return out;
    }
    const reflow: ArchiveNode | null = richText.node('reflowState');
    if (reflow !== null) {
      out.pageWidthDoc = reflow.numberOf('pageWidthInDocumentCoordsKey', 0);
      out.paper.layoutDevice = reflow.stringOf('nativeLayoutDeviceStringKey', '');
    }
    if (out.pageWidthDoc <= 0) {
      out.error = '无法确定页面宽度（reflowState.pageWidthInDocumentCoordsKey 缺失）';
      return out;
    }

    // --- 页高：优先缩略图比例，否则兜底常量 ---
    if (thumbAspect > 0.5 && thumbAspect < 4) {
      out.pageHeightDoc = out.pageWidthDoc * thumbAspect;
    } else {
      out.pageHeightDoc = out.pageWidthDoc * FALLBACK_PAGE_ASPECT;
      out.warnings.push(`缩略图不可用，页高按兜底比例 ${FALLBACK_PAGE_ASPECT} 推导（未经该文件验证）`);
    }

    // 先盘点非手写内容，禁止因 Handwriting Overlay 缺失而提前返回成功。
    const media: ArchiveNode | null = richText.node('mediaObjects');
    if (media !== null) {
      out.inventory.media.found = contentNodeCount(media);
    }
    const pdfs: ArchiveNode | null = richText.node('pdfFiles');
    if (pdfs !== null) {
      out.inventory.pdf.found = contentNodeCount(pdfs);
    }
    const attributed: ArchiveNode | null = richText.node('NBAttributedBackingString');
    if (attributed !== null) {
      const coding: ArchiveNode | null = attributed.node('NBAttributedBackingStringCodingKey');
      const textNode: ArchiveNode | null = coding !== null ? coding.mapValue('stringKey') : null;
      const typedText: string = textNode !== null ? textNode.asText('') : '';
      out.inventory.textCharacters.found = typedText.length;
    }

    // --- 笔画与形状 ---
    const overlay: ArchiveNode | null = richText.node('Handwriting Overlay');
    const hash: ArchiveNode | null = overlay !== null ? overlay.node('SpatialHash') : null;
    if (overlay === null) {
      out.warnings.push('未找到 "Handwriting Overlay"，该笔记可能不含手写内容');
    } else if (hash === null) {
      out.warnings.push('HandwritingObject 缺少 SpatialHash，无笔画可解析');
    }

    if (hash !== null) {
      const curveResult: CurveParseOutcome = NotabilitySessionParser.parseCurves(hash, out.pageHeightDoc);
      out.curves = curveResult.curves;
      out.totalPoints = curveResult.totalPoints;
      out.inventory.handwriting.found = curveResult.expectedCount;
      out.inventory.handwriting.recovered = curveResult.curves.length;
      out.inventory.handwriting.degraded = curveResult.degradedCount;
      out.inventory.handwriting.unquantifiedLoss = curveResult.unquantifiedLoss;
      appendUniqueAll(out.warnings, curveResult.warnings);

      // 形状识别层：内嵌 bplist，独立于曲线，必须解析否则丢失全部直线/圆/矩形
      const shapesData: Uint8Array | null = hash.dataOf('shapes');
      if (shapesData !== null && shapesData.length > 0) {
        const shapeOutcome: ShapeParseOutcome =
          NotabilitySessionParser.parseShapes(shapesData, out.pageHeightDoc);
        out.shapes = shapeOutcome.shapes;
        out.inventory.shapes.found = shapeOutcome.expectedCount;
        out.inventory.shapes.recovered = shapeOutcome.shapes.length;
        out.inventory.shapes.degraded = shapeOutcome.degradedCount;
        out.inventory.shapes.unquantifiedLoss = shapeOutcome.unquantifiedLoss;
        appendUniqueAll(out.warnings, shapeOutcome.warnings);
      }

      // 未解析部分登记（仅在确有内容时登记，避免空容器把结果误标成"部分导入"）
      const bezierDict: ArchiveNode | null = hash.node('bezierPathsDataDictionary');
      if (bezierDict !== null && bezierDict.mapKeys().length > 0) {
        out.unparsed.push(`bezierPathsDataDictionary（${bezierDict.mapKeys().length} 项）：未解析`);
      }
      const groups: ArchiveNode | null = hash.node('groupsArrays');
      if (groups !== null && groups.elements().length > 0) {
        out.unparsed.push(`groupsArrays（${groups.elements().length} 项）：笔画分组，未解析`);
      }
    }

    // --- 页数：由内容推导，并与 index.plist 交叉校验 ---
    let maxPage: number = 0;
    for (const c of out.curves) {
      if (c.pageIndex > maxPage) {
        maxPage = c.pageIndex;
      }
    }
    for (const shape of out.shapes) {
      if (shape.pageIndex > maxPage) {
        maxPage = shape.pageIndex;
      }
    }
    const hasPositionedContent: boolean = out.curves.length > 0 || out.shapes.length > 0;
    const derived: number = hasPositionedContent ? maxPage + 1 : 1;
    out.pageCount = resolveNotabilityPageCount(derived, pageCountHint);
    if (pageCountHint > 0 && pageCountHint !== derived) {
      out.warnings.push(
        `页数不一致：按曲线/形状坐标与页高 ${out.pageHeightDoc.toFixed(2)} 推导 ${derived} 页，` +
        `HandwritingIndex 记录 ${pageCountHint} 页；为避免丢内容已采用上界 ${out.pageCount} 页`);
    }

    out.ok = true;
    return out;
  }

  // 解析 InkedSpatialHash 的并列数组
  private static parseCurves(hash: ArchiveNode, pageHeight: number): CurveParseOutcome {
    const outcome = new CurveParseOutcome();
    const numCurves: number = hash.numberOf('numcurves', 0);
    const numPoints: number = hash.numberOf('numpoints', 0);
    const numFrac: number = hash.numberOf('numfractionalwidths', 0);
    outcome.expectedCount = Math.max(0, numCurves);
    if (numCurves <= 0 || numPoints <= 0) {
      outcome.unquantifiedLoss = numCurves > 0 || numPoints > 0;
      outcome.warnings.push(`InkedSpatialHash 计数异常 numcurves=${numCurves} numpoints=${numPoints}`);
      return outcome;
    }

    const dPoints: Uint8Array | null = hash.dataOf('curvespoints');
    const dNumPts: Uint8Array | null = hash.dataOf('curvesnumpoints');
    if (dPoints === null || dNumPts === null) {
      outcome.warnings.push('缺少 curvespoints 或 curvesnumpoints，无法解析笔画');
      return outcome;
    }
    // 长度自检：不符合预期直接放弃，避免读出垃圾坐标
    if (dPoints.length < numPoints * 8 || dNumPts.length < numCurves * 4) {
      outcome.warnings.push(
        `笔画数据长度不符：curvespoints=${dPoints.length}（期望 ${numPoints * 8}）` +
        `curvesnumpoints=${dNumPts.length}（期望 ${numCurves * 4}）`);
      return outcome;
    }

    const dWidth: Uint8Array | null = hash.dataOf('curveswidth');
    const dColor: Uint8Array | null = hash.dataOf('curvescolors');
    const dStyle: Uint8Array | null = hash.dataOf('curvesstyles');
    const dUuid: Uint8Array | null = hash.dataOf('curveUUIDs');
    const dOptions: Uint8Array | null = hash.dataOf('options');
    const dFrac: Uint8Array | null = hash.dataOf('curvesfractionalwidths');
    const dForce: Uint8Array | null = hash.dataOf('curvesforces');
    const dAlt: Uint8Array | null = hash.dataOf('curvesaltitudeangles');
    const dAzim: Uint8Array | null = hash.dataOf('curvesazimuthunitvector');

    const unknownStyles: number[] = [];
    let pointCursor: number = 0;    // 点索引
    let anchorCursor: number = 0;   // 锚点索引
    let structureMismatch: number = 0;
    let optionsHighWordCount: number = 0;
    let unmappedWidthCount: number = 0;
    let unmappedForceCount: number = 0;
    let unmappedOrientationCount: number = 0;

    for (let ci = 0; ci < numCurves; ci++) {
      const n: number = uint32LE(dNumPts, ci * 4);
      if (n < 4 || pointCursor + n > numPoints) {
        structureMismatch++;
        break;   // 结构已经对不上，停止解析剩余曲线
      }
      // 三次贝塞尔链应满足 n = 3k+1
      if ((n - 1) % 3 !== 0) {
        structureMismatch++;
        break;   // 锚点流已无法可靠对齐，禁止继续把后续曲线属性错配
      }
      const segCount: number = Math.floor((n - 1) / 3);
      const anchorCount: number = segCount + 1;

      const pts: Point2D[] = [];
      let minX: number = Number.MAX_VALUE;
      let minY: number = Number.MAX_VALUE;
      let maxX: number = -Number.MAX_VALUE;
      let maxY: number = -Number.MAX_VALUE;
      for (let i = 0; i < n; i++) {
        const base: number = (pointCursor + i) * 8;
        const x: number = float32From(dPoints, base, true);
        const y: number = float32From(dPoints, base + 4, true);
        pts.push({ x: x, y: y });
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }

      const fracs: number[] = readFloats(dFrac, anchorCursor, anchorCount, numFrac, 1.0);
      const forces: number[] = readFloats(dForce, anchorCursor, anchorCount, numFrac, 1.0);
      const alts: number[] = readFloats(dAlt, anchorCursor, anchorCount, numFrac, Math.PI / 2);
      const azX: number[] = [];
      const azY: number[] = [];
      if (dAzim !== null && anchorCursor + anchorCount <= numFrac && dAzim.length >= numFrac * 8) {
        for (let i = 0; i < anchorCount; i++) {
          const b: number = (anchorCursor + i) * 8;
          azX.push(float32From(dAzim, b, true));
          azY.push(float32From(dAzim, b + 4, true));
        }
      }

      const style: number = dStyle !== null && ci < dStyle.length ? (dStyle[ci] & 0xFF) : STYLE_PEN_OBSERVED;
      if (style !== STYLE_PEN_OBSERVED && unknownStyles.indexOf(style) < 0) {
        unknownStyles.push(style);
      }
      const fidelity: NotabilityCurveFidelity = assessNotabilityCurveFidelity(
        style, fracs, forces, alts, azX, azY);
      if (fidelity.widthUnmapped) {
        unmappedWidthCount++;
      }
      if (fidelity.forceUnmapped) {
        unmappedForceCount++;
      }
      if (fidelity.orientationUnmapped) {
        unmappedOrientationCount++;
      }
      if (fidelity.degraded) {
        outcome.degradedCount++;
      }

      let options: number = 0;
      if (dOptions !== null && dOptions.length >= (ci + 1) * 8) {
        const optionLo: number = uint32LE(dOptions, ci * 8);
        const optionHi: number = uint32LE(dOptions, ci * 8 + 4);
        if (optionHi !== 0) {
          optionsHighWordCount++;
        }
        options = optionHi > 0x1FFFFF ? Number.MAX_SAFE_INTEGER :
          optionHi * 4294967296.0 + optionLo;
      }

      const curve: NotabilityCurve = {
        index: ci,
        uuid: dUuid !== null && dUuid.length >= (ci + 1) * 16 ? hex(dUuid, ci * 16, 16) : '',
        colorArgb: dColor !== null && dColor.length >= (ci + 1) * 4
          ? rgbaToArgb(dColor[ci * 4], dColor[ci * 4 + 1], dColor[ci * 4 + 2], dColor[ci * 4 + 3])
          : rgbaToArgb(0, 0, 0, 255),
        width: dWidth !== null && dWidth.length >= (ci + 1) * 4 ? float32From(dWidth, ci * 4, true) : 1.0,
        style: style,
        options: options,
        points: pts,
        fractionalWidths: fracs,
        forces: forces,
        altitudeAngles: alts,
        azimuthX: azX,
        azimuthY: azY,
        bounds: { left: minX, top: minY, right: maxX, bottom: maxY },
        pageIndex: pageHeight > 0 ? Math.max(0, Math.floor(minY / pageHeight)) : 0,
      };
      outcome.curves.push(curve);
      outcome.totalPoints += n;
      pointCursor += n;
      anchorCursor += anchorCount;
    }

    if (structureMismatch > 0) {
      outcome.warnings.push(
        `${structureMismatch} 条曲线不满足三次贝塞尔链 numpoints=3k+1 的假设，可能有未知编码变体`);
    }
    if (anchorCursor !== numFrac) {
      outcome.warnings.push(
        `锚点数累计 ${anchorCursor} 与 numfractionalwidths=${numFrac} 不符，压感/宽度可能错位`);
    }
    if (unknownStyles.length > 0) {
      outcome.warnings.push(
        `出现未验证的笔画样式值 [${unknownStyles.join(', ')}]（仅样式 ${STYLE_PEN_OBSERVED}=普通笔经实测确认），已按定宽笔处理`);
    }
    if (unmappedWidthCount > 0) {
      outcome.warnings.push(
        `${unmappedWidthCount} 条曲线含非默认 fractionalWidths；原始值已保留，但缺少压感样本基准，当前未映射到变宽渲染`);
    }
    if (unmappedForceCount > 0) {
      outcome.warnings.push(
        `${unmappedForceCount} 条曲线含非默认 force；原始值已保留，但缺少 Apple Pencil 样本基准，当前未映射到压力语义`);
    }
    if (unmappedOrientationCount > 0) {
      outcome.warnings.push(
        `${unmappedOrientationCount} 条曲线含非默认笔姿属性；原始值已保留，但缺少铅笔样本基准，当前未映射到笔姿语义`);
    }
    if (optionsHighWordCount > 0) {
      outcome.warnings.push(
        `${optionsHighWordCount} 条曲线的 64 位 options 高 32 位非零；已保留安全整数范围内的完整值`);
    }
    return outcome;
  }

  // 解析内嵌的形状 bplist（不是归档，是普通 binary plist）
  private static parseShapes(data: Uint8Array, pageHeight: number): ShapeParseOutcome {
    const outcome = new ShapeParseOutcome();
    const parsed: PlistParseResult = BinaryPlistParser.parse(data);
    if (parsed.value === null) {
      outcome.unquantifiedLoss = true;
      outcome.warnings.push(`形状层内嵌 plist 解析失败：${parsed.error}，${data.length} 字节形状内容丢失`);
      return outcome;
    }
    for (let i: number = 0; i < parsed.warnings.length; i++) {
      outcome.warnings.push(`形状层：${parsed.warnings[i]}`);
    }
    const shapesArr: PlistValue | null = parsed.value.dictGet('shapes');
    const kindsArr: PlistValue | null = parsed.value.dictGet('kinds');
    const indicesArr: PlistValue | null = parsed.value.dictGet('indices');
    if (shapesArr === null || kindsArr === null) {
      outcome.unquantifiedLoss = true;
      outcome.warnings.push('形状层缺少 shapes/kinds 数组，未解析');
      return outcome;
    }
    const items: PlistValue[] = shapesArr.arrayItems();
    const kinds: PlistValue[] = kindsArr.arrayItems();
    const indices: PlistValue[] = indicesArr !== null ? indicesArr.arrayItems() : [];
    outcome.expectedCount = items.length;
    if (kinds.length !== items.length) {
      outcome.warnings.push(`形状层 shapes(${items.length}) 与 kinds(${kinds.length}) 数量不符，按较小者处理`);
    }
    const count: number = Math.min(items.length, kinds.length);
    const unknownKinds: string[] = [];
    const unknownStyles: number[] = [];

    for (let i = 0; i < count; i++) {
      const item: PlistValue = items[i];
      const kind: string = kinds[i].asString('');
      const appearance: PlistValue | null = item.dictGet('appearance');
      let colorArgb: number = rgbaToArgb(0, 0, 0, 255);
      let width: number = 1.0;
      let style: number = STYLE_PEN_OBSERVED;
      if (appearance !== null) {
        width = appearance.dictGet('strokeWidth') !== null
          ? (appearance.dictGet('strokeWidth') as PlistValue).asNumber(1.0) : 1.0;
        const styleVal: PlistValue | null = appearance.dictGet('style');
        style = styleVal !== null ? styleVal.asNumber(STYLE_PEN_OBSERVED) : STYLE_PEN_OBSERVED;
        const strokeColor: PlistValue | null = appearance.dictGet('strokeColor');
        const rgba: PlistValue | null = strokeColor !== null ? strokeColor.dictGet('rgba') : null;
        if (rgba !== null) {
          const comps: PlistValue[] = rgba.arrayItems();
          if (comps.length >= 3) {
            const a: number = comps.length >= 4 ? comps[3].asNumber(1.0) : 1.0;
            colorArgb = rgbaToArgb(unitToByte(comps[0].asNumber(0)), unitToByte(comps[1].asNumber(0)),
              unitToByte(comps[2].asNumber(0)), unitToByte(a));
          }
        }
      }

      // 几何：按 kind 分派；未知 kind 不猜测，跳过并告警
      const anchors: Point2D[] = [];
      const cubics: CubicSegment[] = [];
      let isClosed: boolean = false;
      if (kind === 'line') {
        const s: Point2D | null = readPoint(item.dictGet('startPt'));
        const e: Point2D | null = readPoint(item.dictGet('endPt'));
        if (s === null || e === null) {
          outcome.warnings.push(`形状 #${i}（line）缺少 startPt/endPt，已跳过`);
          continue;
        }
        anchors.push(s);
        anchors.push(e);
      } else if (kind === 'rectangle') {
        const ptsVal: PlistValue | null = item.dictGet('points');
        if (ptsVal === null) {
          outcome.warnings.push(`形状 #${i}（rectangle）缺少 points，已跳过`);
          continue;
        }
        for (const pv of ptsVal.arrayItems()) {
          const p: Point2D | null = readPoint(pv);
          if (p !== null) {
            anchors.push(p);
          }
        }
        const closedVal: PlistValue | null = item.dictGet('isClosed');
        isClosed = closedVal !== null && closedVal.asBool(false);
        if (anchors.length < 2) {
          outcome.warnings.push(`形状 #${i}（rectangle）顶点不足，已跳过`);
          continue;
        }
        if (isClosed) {
          anchors.push(anchors[0]);
        }
      } else if (kind === 'circle') {
        const rot: PlistValue | null = item.dictGet('rotatedRect');
        const cornersVal: PlistValue | null = rot !== null ? rot.dictGet('corners') : null;
        const corners: Point2D[] = [];
        if (cornersVal !== null) {
          for (const cv of cornersVal.arrayItems()) {
            const p: Point2D | null = readPoint(cv);
            if (p !== null) {
              corners.push(p);
            }
          }
        }
        if (corners.length < 4) {
          outcome.warnings.push(`形状 #${i}（circle）缺少 rotatedRect.corners，已跳过`);
          continue;
        }
        buildEllipse(corners, anchors, cubics);
        isClosed = true;
      } else {
        if (unknownKinds.indexOf(kind) < 0) {
          unknownKinds.push(kind);
        }
        continue;
      }

      if (style !== STYLE_PEN_OBSERVED) {
        outcome.degradedCount++;
        if (unknownStyles.indexOf(style) < 0) {
          unknownStyles.push(style);
        }
      }

      let minX: number = Number.MAX_VALUE;
      let minY: number = Number.MAX_VALUE;
      let maxX: number = -Number.MAX_VALUE;
      let maxY: number = -Number.MAX_VALUE;
      for (const p of anchors) {
        if (p.x < minX) {
          minX = p.x;
        }
        if (p.y < minY) {
          minY = p.y;
        }
        if (p.x > maxX) {
          maxX = p.x;
        }
        if (p.y > maxY) {
          maxY = p.y;
        }
      }

      const uuidVal: PlistValue | null = item.dictGet('uuid');
      const uuidBytes: Uint8Array | null = uuidVal !== null ? uuidVal.asData() : null;
      const optionsVal: PlistValue | null = item.dictGet('options');
      outcome.shapes.push({
        index: i,
        uuid: uuidBytes !== null && uuidBytes.length >= 16 ? hex(uuidBytes, 0, 16) : '',
        kind: kind,
        zIndex: i < indices.length ? indices[i].asNumber(i) : i,
        colorArgb: colorArgb,
        width: width,
        style: style,
        options: optionsVal !== null ? optionsVal.asNumber(0) : 0,
        anchors: anchors,
        cubics: cubics,
        isClosed: isClosed,
        bounds: { left: minX, top: minY, right: maxX, bottom: maxY },
        pageIndex: pageHeight > 0 ? Math.max(0, Math.floor(minY / pageHeight)) : 0,
      });
    }

    if (unknownKinds.length > 0) {
      outcome.warnings.push(
        `形状层出现未知类型 [${unknownKinds.join(', ')}]（仅 line/circle/rectangle 经实测确认），已跳过未渲染`);
    }
    if (unknownStyles.length > 0) {
      outcome.warnings.push(
        `形状层出现未验证样式值 [${unknownStyles.join(', ')}]，几何已恢复但样式按普通定宽笔退化`);
    }
    return outcome;
  }

  // 转为内部模型，按页分组。
  // targetPageWidthVp：把 Notability 文档坐标缩放到的画布宽度
  // 曲线与形状按 shape.zIndex 交错还原绘制顺序（zIndex=i 表示插在第 i 条曲线之前）
  static toPageElements(session: NotabilitySession, targetPageWidthVp: number): NotabilityPageElements[] {
    const pages: NotabilityPageElements[] = [];
    if (!session.ok || session.pageWidthDoc <= 0) {
      return pages;
    }
    const pageTotal: number = Math.max(1, session.pageCount);
    for (let i = 0; i < pageTotal; i++) {
      pages.push({ pageIndex: i, strokes: [], shapes: [], elementOrder: [] });
    }
    const scale: number = targetPageWidthVp / session.pageWidthDoc;

    const sortedShapes: NotabilityShape[] = [];
    let shapeOrderChanged: boolean = false;
    for (let i: number = 0; i < session.shapes.length; i++) {
      sortedShapes.push(session.shapes[i]);
      if (i > 0 && session.shapes[i - 1].zIndex > session.shapes[i].zIndex) {
        shapeOrderChanged = true;
      }
    }
    sortedShapes.sort((left: NotabilityShape, right: NotabilityShape): number => {
      if (left.zIndex !== right.zIndex) {
        return left.zIndex - right.zIndex;
      }
      return left.index - right.index;
    });
    if (shapeOrderChanged) {
      const warning: string = '形状 indices 非升序，已按 zIndex 稳定排序后还原绘制层次';
      if (session.warnings.indexOf(warning) < 0) {
        session.warnings.push(warning);
      }
    }
    let clampedItemCount: number = 0;
    for (let i: number = 0; i < session.curves.length; i++) {
      if (session.curves[i].pageIndex >= pageTotal) {
        clampedItemCount++;
      }
    }
    for (let i: number = 0; i < sortedShapes.length; i++) {
      if (sortedShapes[i].pageIndex >= pageTotal) {
        clampedItemCount++;
      }
    }
    if (clampedItemCount > 0) {
      const warning: string = `${clampedItemCount} 个笔画/形状页号超出页数，已连同坐标偏移钳制到末页`;
      if (session.warnings.indexOf(warning) < 0) {
        session.warnings.push(warning);
      }
    }

    let shapeCursor: number = 0;
    for (let ci = 0; ci < session.curves.length; ci++) {
      // 先补齐所有该插在本条曲线之前的形状
      while (shapeCursor < sortedShapes.length && sortedShapes[shapeCursor].zIndex <= ci) {
        NotabilitySessionParser.pushShape(pages, sortedShapes[shapeCursor], session, scale, pageTotal);
        shapeCursor++;
      }
      NotabilitySessionParser.pushCurve(pages, session.curves[ci], session, scale, pageTotal);
    }
    while (shapeCursor < sortedShapes.length) {
      NotabilitySessionParser.pushShape(pages, sortedShapes[shapeCursor], session, scale, pageTotal);
      shapeCursor++;
    }
    return pages;
  }

  private static pushCurve(pages: NotabilityPageElements[], curve: NotabilityCurve,
    session: NotabilitySession, scale: number, pageTotal: number): void {
    const pi: number = curve.pageIndex < pageTotal ? curve.pageIndex : pageTotal - 1;
    const yOffset: number = pi * session.pageHeightDoc;

    // 页内坐标 + 缩放
    const local: Point2D[] = [];
    for (const p of curve.points) {
      local.push({ x: p.x * scale, y: (p.y - yOffset) * scale });
    }
    const segCount: number = Math.floor((local.length - 1) / 3);
    const segments: CubicSegment[] = [];
    for (let s = 0; s < segCount; s++) {
      segments.push({
        p0: local[s * 3], p1: local[s * 3 + 1],
        p2: local[s * 3 + 2], p3: local[s * 3 + 3],
      });
    }
    // 路径点取锚点（与 fractionalWidths 一一对应）
    const pathPoints: StrokePathPoint[] = [];
    for (let a = 0; a <= segCount; a++) {
      const idx: number = a * 3;
      if (idx >= local.length) {
        break;
      }
      pathPoints.push({
        position: local[idx],
        widthFactor: a < curve.fractionalWidths.length ? curve.fractionalWidths[a] : 1.0,
        pressure: -1,
        altitudeAngleRadians: Math.PI / 2,
        azimuthUnitX: 1,
        azimuthUnitY: 0,
      });
    }

    const spec: RenderSpec = {
      color: curve.colorArgb,
      brushWidth: curve.width * scale,
      inkStyle: InkStyle.FIXED_WIDTH,   // 实测样式 3 为定宽普通笔
      isHighlighter: false,
      isPencil: false,
    };
    const stroke: StrokeElementData = {
      id: curve.uuid.length > 0 ? `nb-${curve.uuid}` : `nb-${pi}-${curve.index}`,
      pathPoints: pathPoints,
      cubicSegments: segments,
      splatPoints: [],
      renderSpec: spec,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: {
        left: curve.bounds.left * scale,
        top: (curve.bounds.top - yOffset) * scale,
        right: curve.bounds.right * scale,
        bottom: (curve.bounds.bottom - yOffset) * scale,
      },
      maskPath: [],
      isFinished: true,
    };
    pages[pi].strokes.push(stroke);
    pages[pi].elementOrder.push({
      kind: PageElementKind.STROKE, elementId: stroke.id, zIndex: pages[pi].elementOrder.length,
    });
  }

  private static pushShape(pages: NotabilityPageElements[], shape: NotabilityShape,
    session: NotabilitySession, scale: number, pageTotal: number): void {
    if (shape.anchors.length === 0) {
      return;
    }
    const pi: number = shape.pageIndex < pageTotal ? shape.pageIndex : pageTotal - 1;
    const yOffset: number = pi * session.pageHeightDoc;

    const anchors: Point2D[] = [];
    for (const p of shape.anchors) {
      anchors.push({ x: p.x * scale, y: (p.y - yOffset) * scale });
    }
    const id: string = shape.uuid.length > 0 ? `nbs-${shape.uuid}` : `nbs-${pi}-${shape.index}`;
    const identity: number[] = [1, 0, 0, 0, 1, 0, 0, 0, 1];
    const strokeWidth: number = shape.width * scale;
    let semantic: ShapeElement | null = null;
    if (shape.kind === 'line' && anchors.length >= 2) {
      semantic = {
        id: id, type: ElementType.LINE, transform: identity, bounds: emptyRect(),
        start: anchors[0], controlPoint1: null, controlPoint2: null,
        end: anchors[anchors.length - 1], arrowHead: ShapeArrowHead.NONE,
        color: shape.colorArgb, strokeWidth: strokeWidth, fillColor: null,
      };
    } else if (shape.kind === 'rectangle' && anchors.length >= 2) {
      const vertices: Point2D[] = anchors.slice();
      if (shape.isClosed && vertices.length > 1 && samePoint(vertices[0], vertices[vertices.length - 1])) {
        vertices.pop();
      }
      semantic = {
        id: id, type: ElementType.POLYGON, transform: identity, bounds: emptyRect(),
        vertices: vertices, isClosed: shape.isClosed, color: shape.colorArgb,
        strokeWidth: strokeWidth, fillColor: null,
      };
    } else if (shape.kind === 'circle' && anchors.length >= 4) {
      const center: Point2D = {
        x: (anchors[0].x + anchors[2].x) / 2,
        y: (anchors[0].y + anchors[2].y) / 2,
      };
      const axisX: Point2D = { x: anchors[0].x - center.x, y: anchors[0].y - center.y };
      const axisY: Point2D = { x: anchors[1].x - center.x, y: anchors[1].y - center.y };
      semantic = {
        id: id, type: ElementType.ELLIPSE, transform: identity, bounds: emptyRect(),
        center: center,
        radiusX: Math.sqrt(axisX.x * axisX.x + axisX.y * axisX.y),
        radiusY: Math.sqrt(axisY.x * axisY.x + axisY.y * axisY.y),
        rotationRadians: Math.atan2(axisX.y, axisX.x), color: shape.colorArgb,
        strokeWidth: strokeWidth, fillColor: null,
      };
    }
    if (semantic === null) {
      return;
    }
    semantic.bounds = recomputeShapeBounds(semantic);
    pages[pi].shapes.push(semantic);
    pages[pi].elementOrder.push({
      kind: PageElementKind.SHAPE, elementId: semantic.id, zIndex: pages[pi].elementOrder.length,
    });
  }

  // 从 PNG 头部读取宽高比（高/宽）。非 PNG 或损坏返回 0
  static pngAspect(png: Uint8Array): number {
    if (png === null || png.length < 24) {
      return 0;
    }
    // PNG 签名 89 50 4E 47 0D 0A 1A 0A，随后 IHDR：长度(4)+"IHDR"(4)+宽(4)+高(4)，均为大端
    if (png[0] !== 0x89 || png[1] !== 0x50 || png[2] !== 0x4E || png[3] !== 0x47) {
      return 0;
    }
    const w: number = ((png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19]) >>> 0;
    const h: number = ((png[20] << 24) | (png[21] << 16) | (png[22] << 8) | png[23]) >>> 0;
    if (w === 0 || h === 0) {
      return 0;
    }
    return h / w;
  }

  // 从 HandwritingIndex/index.plist 读取页数（普通 binary plist，非归档）
  static pageCountFromIndex(data: Uint8Array, warnings?: string[]): number {
    const parsed: PlistParseResult = BinaryPlistParser.parse(data);
    if (warnings !== undefined) {
      for (let i: number = 0; i < parsed.warnings.length; i++) {
        warnings.push(`HandwritingIndex：${parsed.warnings[i]}`);
      }
    }
    const root: PlistValue | null = parsed.value;
    if (root === null) {
      return 0;
    }
    const pages: PlistValue | null = root.dictGet('pages');
    if (pages === null) {
      return 0;
    }
    if (pages.type === PlistType.DICT) {
      return pages.dictKeys().length;
    }
    if (pages.type === PlistType.ARRAY || pages.type === PlistType.SET) {
      return pages.arrayItems().length;
    }
    if (warnings !== undefined) {
      warnings.push(`HandwritingIndex.pages 类型不支持：${pages.describe()}`);
    }
    return 0;
  }
}

class CurveParseOutcome {
  curves: NotabilityCurve[] = [];
  totalPoints: number = 0;
  expectedCount: number = 0;
  degradedCount: number = 0;
  unquantifiedLoss: boolean = false;
  warnings: string[] = [];
}

class ShapeParseOutcome {
  shapes: NotabilityShape[] = [];
  expectedCount: number = 0;
  degradedCount: number = 0;
  unquantifiedLoss: boolean = false;
  warnings: string[] = [];
}

function createContentCount(): NotabilityContentCount {
  return { found: 0, recovered: 0, degraded: 0, unquantifiedLoss: false };
}

export function createNotabilityContentInventory(): NotabilityContentInventory {
  return {
    handwriting: createContentCount(), shapes: createContentCount(),
    textCharacters: createContentCount(), media: createContentCount(),
    pdf: createContentCount(), audio: createContentCount(),
  };
}

function appendUniqueAll(target: string[], values: string[]): void {
  for (let i: number = 0; i < values.length; i++) {
    if (target.indexOf(values[i]) < 0) {
      target.push(values[i]);
    }
  }
}

function contentNodeCount(node: ArchiveNode): number {
  return Math.max(node.elements().length, node.mapKeys().length);
}

function appendContentLoss(target: string[], label: string, unit: string,
  count: NotabilityContentCount): void {
  if (count.found > count.recovered) {
    target.push(`${label}：发现 ${count.found} ${unit}，恢复 ${count.recovered} ${unit}，` +
      `丢失 ${count.found - count.recovered} ${unit}`);
  }
  if (count.degraded > 0) {
    target.push(`${label}：${count.degraded} ${unit}已恢复几何/内容，但样式发生保真退化`);
  }
  if (count.unquantifiedLoss) {
    target.push(`${label}：检测到内容层，但结构损坏，数量未知且未能恢复`);
  }
}

// [x, y] 形式的点
function readPoint(v: PlistValue | null): Point2D | null {
  if (v === null) {
    return null;
  }
  const comps: PlistValue[] = v.arrayItems();
  if (comps.length < 2) {
    return null;
  }
  return { x: comps[0].asNumber(0), y: comps[1].asNumber(0) };
}

// 0~1 浮点分量 → 0~255 字节
function unitToByte(v: number): number {
  const b: number = Math.round(v * 255);
  if (b < 0) {
    return 0;
  }
  return b > 255 ? 255 : b;
}

// 三次贝塞尔逼近四分之一椭圆的控制点比例
const ELLIPSE_KAPPA: number = 0.5522847498307936;

// 椭圆内切于 corners 构成的平行四边形：中心 C，半轴 u=(c1-c0)/2、v=(c3-c0)/2。
// 生成 4 个象限锚点与 4 段贝塞尔弧（首尾闭合）。
function buildEllipse(corners: Point2D[], anchorsOut: Point2D[], cubicsOut: CubicSegment[]): void {
  const c0: Point2D = corners[0];
  const c1: Point2D = corners[1];
  const c3: Point2D = corners[3];
  const cx: number = (corners[0].x + corners[1].x + corners[2].x + corners[3].x) / 4;
  const cy: number = (corners[0].y + corners[1].y + corners[2].y + corners[3].y) / 4;
  const ux: number = (c1.x - c0.x) / 2;
  const uy: number = (c1.y - c0.y) / 2;
  const vx: number = (c3.x - c0.x) / 2;
  const vy: number = (c3.y - c0.y) / 2;
  // 锚点：C+u, C+v, C-u, C-v
  const a: Point2D[] = [
    { x: cx + ux, y: cy + uy },
    { x: cx + vx, y: cy + vy },
    { x: cx - ux, y: cy - uy },
    { x: cx - vx, y: cy - vy },
  ];
  const ku: Point2D = { x: ux * ELLIPSE_KAPPA, y: uy * ELLIPSE_KAPPA };
  const kv: Point2D = { x: vx * ELLIPSE_KAPPA, y: vy * ELLIPSE_KAPPA };
  cubicsOut.push({
    p0: a[0], p1: { x: a[0].x + kv.x, y: a[0].y + kv.y },
    p2: { x: a[1].x + ku.x, y: a[1].y + ku.y }, p3: a[1],
  });
  cubicsOut.push({
    p0: a[1], p1: { x: a[1].x - ku.x, y: a[1].y - ku.y },
    p2: { x: a[2].x + kv.x, y: a[2].y + kv.y }, p3: a[2],
  });
  cubicsOut.push({
    p0: a[2], p1: { x: a[2].x - kv.x, y: a[2].y - kv.y },
    p2: { x: a[3].x - ku.x, y: a[3].y - ku.y }, p3: a[3],
  });
  cubicsOut.push({
    p0: a[3], p1: { x: a[3].x + ku.x, y: a[3].y + ku.y },
    p2: { x: a[0].x - kv.x, y: a[0].y - kv.y }, p3: a[0],
  });
  for (const p of a) {
    anchorsOut.push(p);
  }
  anchorsOut.push(a[0]);
}

// 从 f32 小端数组按锚点区间读取；越界回落到默认值
function readFloats(data: Uint8Array | null, start: number, count: number,
  total: number, fallback: number): number[] {
  const out: number[] = [];
  const usable: boolean = data !== null && data.length >= total * 4 && start + count <= total;
  for (let i = 0; i < count; i++) {
    out.push(usable && data !== null ? float32From(data, (start + i) * 4, true) : fallback);
  }
  return out;
}

// RGBA 字节 → 有符号 ARGB（与 BrushSpec.color 约定一致，黑色 = -16777216）
function rgbaToArgb(r: number, g: number, b: number, a: number): number {
  return (((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)) | 0;
}

function hex(data: Uint8Array, offset: number, length: number): string {
  let s: string = '';
  for (let i = 0; i < length; i++) {
    const v: number = data[offset + i] & 0xFF;
    s += v < 16 ? `0${v.toString(16)}` : v.toString(16);
  }
  return s;
}

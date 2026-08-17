import { describe, it, expect } from '@ohos/hypium';
import { ElementType, ImageElement, MathElement, PolygonElement,
  TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { SelectionMode, SelectionTool } from '../main/ets/rendering/SelectionTool';
import { OriginalSelectionGroup } from '../main/ets/core/model/OriginalGroupSelection';

function stroke(id: string): StrokeElementData {
  return {
    id: id, pathPoints: [], cubicSegments: [], splatPoints: [],
    renderSpec: { color: 0xFF000000, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 10, bottom: 10 }, maskPath: [], isFinished: true,
  };
}

function shape(id: string): PolygonElement {
  return {
    id: id, type: ElementType.POLYGON,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 20, top: 20, right: 40, bottom: 40 },
    vertices: [{ x: 20, y: 20 }, { x: 40, y: 20 }, { x: 30, y: 40 }],
    isClosed: true, color: 0xFF000000, strokeWidth: 2, fillColor: null,
  };
}

function textBlock(id: string): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 50, top: 50, right: 90, bottom: 80 }, richText: id,
    textOrigin: { x: 50, y: 50 }, blockWidth: 40, blockHeight: 30,
    rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
    fontSize: 12, fontColor: 0xFF000000,
  };
}

function rotatedTextBlock(id: string): TextBlockElement {
  const angle: number = Math.PI / 4;
  return {
    id: id, type: ElementType.TEXT,
    transform: [Math.cos(angle), -Math.sin(angle), 100,
      Math.sin(angle), Math.cos(angle), 100, 0, 0, 1],
    bounds: { left: 85.857864, top: 100, right: 170.710679, bottom: 184.852814 },
    richText: id, textOrigin: { x: 0, y: 0 }, blockWidth: 100, blockHeight: 20,
    rotationRadians: angle, contentLeftInset: 4, contentTopInset: 4,
    fontSize: 12, fontColor: 0xFF000000,
  };
}

function imageBlock(id: string): ImageElement {
  const bits: string[] = ['1', '2', '3', '4', '5', '6', '7', '8'];
  return {
    id: id, type: ElementType.IMAGE, transform: [1, 0, 100, 0, 1, 100, 0, 0, 1],
    bounds: { left: 100, top: 100, right: 180, bottom: 160 }, assetHash: bits.join(':'),
    assetHashBits: bits, fileName: 'image.png', mimeType: 'image/png', fileSize: 10,
    intrinsicWidth: 80, intrinsicHeight: 60, cropRect: null, blockWidth: 80, blockHeight: 60,
    rotationRadians: 0, corner: 0, textWrap: 0, enableCaption: false, webUrl: null,
    imageFlippedHorizontally: false, imageFlippedVertically: false, positionLocked: false,
  };
}

function mathBlock(id: string): MathElement {
  return {
    id: id, type: ElementType.MATH, transform: [1, 0, 200, 0, 1, 200, 0, 0, 1],
    bounds: { left: 200, top: 200, right: 260, bottom: 240 }, latex: 'x^2',
    color: 0xFF000000, blockWidth: 60, blockHeight: 40, rotationRadians: 0,
    corner: 0, textWrap: 0, enableCaption: false, positionLocked: false,
  };
}

export default function selectionToolTest() {
  describe('SelectionTool shape selection', () => {
    it('selects shape-only rectangle hits and clears both id sets', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 15, y: 15 });
      tool.updateSelection({ x: 45, y: 45 });
      const ids: string[] = tool.finalizeSelection([stroke('outside')], [shape('shape-1')]);
      expect(ids.length).assertEqual(1);
      expect(ids[0]).assertEqual('shape-1');
      expect(tool.getState().selectedStrokeIds.length).assertEqual(0);
      expect(tool.getState().selectedShapeIds[0]).assertEqual('shape-1');
      expect(tool.deleteSelected()[0]).assertEqual('shape-1');
      expect(tool.getState().isActive).assertFalse();
      expect(tool.getState().selectedShapeIds.length).assertEqual(0);
    });

    it('restores mixed pasted selection state without sharing caller arrays', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      const strokeIds: string[] = ['stroke-1'];
      const shapeIds: string[] = ['shape-1'];
      tool.selectElementIds(strokeIds, shapeIds);
      strokeIds[0] = 'mutated';
      shapeIds[0] = 'mutated';
      expect(tool.getState().selectedStrokeIds[0]).assertEqual('stroke-1');
      expect(tool.getState().selectedShapeIds[0]).assertEqual('shape-1');
      expect(tool.getState().isActive).assertTrue();
      tool.moveSelected(12, 8);
      expect(tool.getState().transform[2]).assertEqual(12);
      tool.selectElementIds(['stroke-1'], ['shape-1']);
      expect(tool.getState().transform[2]).assertEqual(0);
      expect(tool.getState().transform[5]).assertEqual(0);
      tool.deselect();
      expect(tool.getState().selectedStrokeIds.length).assertEqual(0);
      expect(tool.getState().selectedShapeIds.length).assertEqual(0);
    });

    it('selects and clears text-only content with the unified state', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 45, y: 45 });
      tool.updateSelection({ x: 95, y: 85 });
      const ids: string[] = tool.finalizeSelection([], [], [textBlock('text-1')]);
      expect(ids[0]).assertEqual('text-1');
      expect(tool.getState().selectedTextBlockIds[0]).assertEqual('text-1');
      const callerIds: string[] = ['text-2'];
      tool.selectElementIds([], [], callerIds);
      callerIds[0] = 'mutated';
      expect(tool.getState().selectedTextBlockIds[0]).assertEqual('text-2');
      tool.deselect();
      expect(tool.getState().selectedTextBlockIds.length).assertEqual(0);
    });

    it('rejects a rectangle that only touches a rotated Text AABB', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 166, y: 102 });
      tool.updateSelection({ x: 170, y: 106 });
      const ids: string[] = tool.finalizeSelection([], [], [rotatedTextBlock('rotated')]);
      expect(ids.length).assertEqual(0);
      expect(tool.getState().selectedTextBlockIds.length).assertEqual(0);
    });

    it('selects a Text Block when a lasso edge crosses it without containing its AABB center', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      tool.beginSelection(SelectionMode.LASSO, { x: 48, y: 55 });
      tool.updateSelection({ x: 52, y: 55 });
      tool.updateSelection({ x: 52, y: 60 });
      tool.updateSelection({ x: 48, y: 60 });
      const ids: string[] = tool.finalizeSelection([], [], [textBlock('lasso-edge')]);
      expect(ids.length).assertEqual(1);
      expect(ids[0]).assertEqual('lasso-edge');
    });

    it('selects original position-locked text blocks so they can be unlocked', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      const locked: TextBlockElement = textBlock('locked');
      locked.positionLocked = true;
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 45, y: 45 });
      tool.updateSelection({ x: 95, y: 85 });
      const ids: string[] = tool.finalizeSelection([], [], [locked]);
      expect(ids[0]).assertEqual('locked');
      expect(tool.getState().selectedTextBlockIds[0]).assertEqual('locked');
    });

    it('selects image blocks by bounds including position-locked images', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      const editable: ImageElement = imageBlock('image-1');
      const locked: ImageElement = imageBlock('image-locked');
      locked.positionLocked = true;
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 90, y: 90 });
      tool.updateSelection({ x: 190, y: 170 });
      const ids: string[] = tool.finalizeSelection([], [], [], [editable, locked]);
      expect(ids.length).assertEqual(2);
      expect(ids[0]).assertEqual('image-1');
      expect(tool.getState().selectedImageIds[0]).assertEqual('image-1');
      expect(tool.getState().selectedImageIds[1]).assertEqual('image-locked');
      const callerIds: string[] = ['image-2'];
      tool.selectElementIds([], [], [], callerIds);
      callerIds[0] = 'mutated';
      expect(tool.getState().selectedImageIds[0]).assertEqual('image-2');
      tool.deselect();
      expect(tool.getState().selectedImageIds.length).assertEqual(0);
    });

    it('expands an original Group hit and keeps position-locked Shapes selectable', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      const editableShape: PolygonElement = shape('shape-1');
      const lockedShape: PolygonElement = shape('shape-locked');
      lockedShape.positionLocked = true;
      const groups: OriginalSelectionGroup[] = [{ id: 'group-1', timestamp: 30, siteId: 2,
        members: ['shape-1', 'stroke-1'] }];
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 15, y: 15 });
      tool.updateSelection({ x: 45, y: 45 });
      const ids: string[] = tool.finalizeSelection(
        [stroke('stroke-1')], [editableShape, lockedShape], [], [], groups);
      expect(ids.length).assertEqual(3);
      expect(tool.getState().selectedStrokeIds[0]).assertEqual('stroke-1');
      expect(tool.getState().selectedShapeIds[0]).assertEqual('shape-1');
      expect(tool.getState().selectedGroupIds[0]).assertEqual('group-1');
      expect(tool.getState().selectedShapeIds.indexOf('shape-locked') >= 0).assertTrue();
    });

    it('selects locked Math when its bounds are hit', 0, () => {
      const tool: SelectionTool = new SelectionTool();
      const editableMath: MathElement = mathBlock('math-1');
      const lockedMath: MathElement = mathBlock('math-locked');
      lockedMath.positionLocked = true;
      const groups: OriginalSelectionGroup[] = [{ id: 'group-math', timestamp: 40, siteId: 1,
        members: ['shape-1', 'math-1'] }];
      tool.beginSelection(SelectionMode.RECTANGLE, { x: 15, y: 15 });
      tool.updateSelection({ x: 270, y: 250 });
      const ids: string[] = tool.finalizeSelection(
        [], [shape('shape-1')], [], [], groups, [editableMath, lockedMath]);
      expect(ids.length).assertEqual(3);
      expect(tool.getState().selectedShapeIds[0]).assertEqual('shape-1');
      expect(tool.getState().selectedMathIds[0]).assertEqual('math-1');
      expect(tool.getState().selectedMathIds.indexOf('math-locked') >= 0).assertTrue();
      expect(tool.getState().selectedGroupIds[0]).assertEqual('group-math');
    });
  });
}

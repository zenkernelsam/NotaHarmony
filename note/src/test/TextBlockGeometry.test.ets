import { describe, it, expect } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import {
  cloneTextBlockElement, eraserPathHitsTextBlock, pointHitsTextBlock,
  isTextBlockPositionLocked, textBlockTransformComponents, textBlockWorldBounds,
  transformTextBlockElements,
} from '../main/ets/core/model/TextBlockGeometry';
import { TextBlockTool } from '../main/ets/rendering/TextBlockTool';

function textBlock(id: string = 'text-1'): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 60 }, richText: 'hello',
    textOrigin: { x: 10, y: 20 }, blockWidth: 100, blockHeight: 40,
    rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
    fontSize: 16, fontColor: 0xFF123456,
  };
}

function close(actual: number, expected: number): boolean {
  return Math.abs(actual - expected) < 0.000001;
}

export default function textBlockGeometryTest() {
  describe('TextBlockGeometry', () => {
    it('deep-clones mutable geometry', 0, () => {
      const source: TextBlockElement = textBlock();
      const cloned: TextBlockElement = cloneTextBlockElement(source);
      cloned.transform[2] = 99;
      cloned.textOrigin.x = 99;
      cloned.bounds.left = 99;
      expect(source.transform[2]).assertEqual(0);
      expect(source.textOrigin.x).assertEqual(10);
      expect(source.bounds.left).assertEqual(10);
    });

    it('derives world bounds from local geometry after translation and rotation', 0, () => {
      const source: TextBlockElement = textBlock();
      const moved: TextBlockElement[] = transformTextBlockElements(
        [source], ['text-1'], [1, 0, 5, 0, 1, 7, 0, 0, 1]);
      expect(moved[0].bounds.left).assertEqual(15);
      expect(moved[0].bounds.top).assertEqual(27);
      const rotated: TextBlockElement[] = transformTextBlockElements(
        [source], ['text-1'], [0, -1, 0, 1, 0, 0, 0, 0, 1]);
      expect(close(rotated[0].bounds.left, -60)).assertTrue();
      expect(close(rotated[0].bounds.top, 10)).assertTrue();
      expect(close(rotated[0].bounds.right, -20)).assertTrue();
      expect(close(rotated[0].bounds.bottom, 110)).assertTrue();
    });

    it('does not accumulate AABB growth across repeated rotations', 0, () => {
      let current: TextBlockElement = textBlock();
      const quarterTurn: number[] = [0, -1, 0, 1, 0, 0, 0, 0, 1];
      for (let i: number = 0; i < 4; i++) {
        current = transformTextBlockElements([current], ['text-1'], quarterTurn)[0];
      }
      expect(close(current.bounds.left, 10)).assertTrue();
      expect(close(current.bounds.top, 20)).assertTrue();
      expect(close(current.bounds.right, 110)).assertTrue();
      expect(close(current.bounds.bottom, 60)).assertTrue();
    });

    it('uses the transformed quadrilateral for hit testing and object erasing', 0, () => {
      const source: TextBlockElement = textBlock();
      const angle: number = Math.PI / 4;
      source.transform = [Math.cos(angle), -Math.sin(angle), 0,
        Math.sin(angle), Math.cos(angle), 0, 0, 0, 1];
      source.bounds = textBlockWorldBounds(source);
      expect(pointHitsTextBlock({ x: -7, y: 64 }, source)).assertTrue();
      expect(pointHitsTextBlock({ x: source.bounds.left + 1, y: source.bounds.top + 1 }, source)).assertFalse();
      expect(eraserPathHitsTextBlock([{ x: -7, y: 64 }], source, 2)).assertTrue();
      expect(eraserPathHitsTextBlock([{ x: 200, y: 200 }], source, 20)).assertFalse();
      expect(eraserPathHitsTextBlock([
        { x: source.bounds.left - 4, y: source.bounds.top },
        { x: source.bounds.right + 4, y: source.bounds.bottom },
      ], source, 8)).assertTrue();
    });

    it('keeps original position-locked blocks immutable and unhittable', 0, () => {
      const source: TextBlockElement = textBlock();
      source.positionLocked = true;
      const moved: TextBlockElement = transformTextBlockElements(
        [source], ['text-1'], [1, 0, 50, 0, 1, 60, 0, 0, 1])[0];
      expect(isTextBlockPositionLocked(moved)).assertTrue();
      expect(moved.transform[2]).assertEqual(0);
      expect(moved.transform[5]).assertEqual(0);
      expect(pointHitsTextBlock({ x: 20, y: 30 }, moved)).assertFalse();
      expect(eraserPathHitsTextBlock([{ x: 20, y: 30 }], moved, 8)).assertFalse();
      expect(cloneTextBlockElement(moved).positionLocked).assertTrue();
    });

    it('preserves transform while text editing recomputes world bounds', 0, () => {
      const tool: TextBlockTool = new TextBlockTool();
      const source: TextBlockElement = textBlock();
      source.transform = [2, 0, 30, 0, 2, 40, 0, 0, 1];
      source.bounds = textBlockWorldBounds(source);
      const updated: TextBlockElement = tool.updateText(source, 'one\ntwo\nthree');
      expect(updated.transform[0]).assertEqual(2);
      expect(updated.transform[2]).assertEqual(30);
      expect(updated.blockHeight).assertEqual(80);
      expect(updated.bounds.bottom).assertEqual(240);
      expect(source.blockHeight).assertEqual(40);
    });

    it('preserves original rich-text state for an unchanged editor commit', 0, () => {
      const tool: TextBlockTool = new TextBlockTool();
      const source: TextBlockElement = textBlock();
      source.blockHeight = 91;
      source.bounds = textBlockWorldBounds(source);
      source.characterStyleRuns = [{ start: 0, end: 5, style: { bold: true } }];
      source.paragraphStyleRuns = [{ start: 0, end: 5, style: { alignment: 2 } }];
      const updated: TextBlockElement = tool.updateText(source, 'hello');
      expect(updated.blockHeight).assertEqual(91);
      expect(updated.characterStyleRuns?.length).assertEqual(1);
      expect(updated.characterStyleRuns?.[0].style.bold).assertTrue();
      expect(updated.paragraphStyleRuns?.[0].style.alignment).assertEqual(2);
      expect(updated).assertNotEqual(source);
      if (updated.characterStyleRuns !== undefined) {
        updated.characterStyleRuns[0].style.bold = false;
      }
      expect(source.characterStyleRuns?.[0].style.bold).assertTrue();
    });

    it('writes measured resize-to-fit width and transformed bounds atomically', 0, () => {
      const tool: TextBlockTool = new TextBlockTool();
      const source: TextBlockElement = textBlock();
      source.resizesWidthToFitText = true;
      source.transform = [2, 0, 30, 0, 2, 40, 0, 0, 1];
      source.bounds = textBlockWorldBounds(source);
      const updated: TextBlockElement = tool.updateWidthToFit(source, 81.2);
      expect(updated.blockWidth).assertEqual(82);
      expect(updated.bounds.left).assertEqual(50);
      expect(updated.bounds.right).assertEqual(214);
      expect(source.blockWidth).assertEqual(100);

      source.resizesWidthToFitText = false;
      expect(tool.updateWidthToFit(source, 60).blockWidth).assertEqual(100);
      source.resizesWidthToFitText = true;
      expect(tool.updateWidthToFit(source, Number.NaN).blockWidth).assertEqual(100);
    });

    it('decomposes signed scale and rotation for the editing overlay', 0, () => {
      const source: TextBlockElement = textBlock();
      source.transform = [-2, 0, 100, 0, 3, 50, 0, 0, 1];
      const components = textBlockTransformComponents(source);
      expect(close(components.scaleX, 2)).assertTrue();
      expect(close(components.scaleY, -3)).assertTrue();
      expect(close(Math.abs(components.rotationRadians), Math.PI)).assertTrue();
      expect(components.origin.x).assertEqual(80);
      expect(components.origin.y).assertEqual(110);
    });
  });
}

import { describe, expect, it } from '@ohos/hypium';
import { ElementType, MathElement } from '../main/ets/core/model/ElementTypes';
import { cloneMathElement, mathBlockWorldBounds } from '../main/ets/core/model/MathBlockGeometry';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';

function mathBlock(): MathElement {
  return {
    id: 'math-1', type: ElementType.MATH,
    transform: [0, -1, 30, 1, 0, 40, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 30, bottom: 80 },
    latex: '\\frac{a}{b}', color: 0xFF102030 | 0,
    blockWidth: 40, blockHeight: 20, rotationRadians: Math.PI / 2,
    corner: 0, textWrap: 0, enableCaption: false, positionLocked: false,
  };
}

export default function mathBlockGeometryTest() {
  describe('Original MATH block geometry', () => {
    it('keeps MATH distinct from text and image element kinds', 0, () => {
      expect(ElementType.MATH === ElementType.TEXT).assertFalse();
      expect(ElementType.MATH === ElementType.IMAGE).assertFalse();
      expect(PageElementKind.MATH === PageElementKind.TEXT).assertFalse();
      expect(PageElementKind.MATH === PageElementKind.IMAGE).assertFalse();
    });

    it('deep-clones mutable geometry while preserving LaTeX and signed ARGB', 0, () => {
      const source: MathElement = mathBlock();
      const cloned: MathElement = cloneMathElement(source);
      cloned.transform[2] = 99;
      cloned.bounds.left = 99;
      expect(source.transform[2]).assertEqual(30);
      expect(source.bounds.left).assertEqual(10);
      expect(cloned.latex).assertEqual('\\frac{a}{b}');
      expect(cloned.color).assertEqual(-15720400);
    });

    it('derives the world AABB from the transformed local block rectangle', 0, () => {
      const bounds = mathBlockWorldBounds(mathBlock());
      expect(bounds.left).assertEqual(10);
      expect(bounds.top).assertEqual(40);
      expect(bounds.right).assertEqual(30);
      expect(bounds.bottom).assertEqual(80);
    });

    it('preserves empty LaTeX as an explicit non-rendering value', 0, () => {
      const source: MathElement = mathBlock();
      source.latex = '';
      expect(cloneMathElement(source).latex.length).assertEqual(0);
    });
  });
}

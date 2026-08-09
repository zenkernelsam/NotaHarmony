import { describe, it, expect } from '@ohos/hypium';
import { ElementType, PolygonElement } from '../main/ets/core/model/ElementTypes';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { SelectionMode, SelectionTool } from '../main/ets/rendering/SelectionTool';

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
  });
}

import { describe, it, expect } from '@ohos/hypium';
import { BrushStyle, EditorToolboxState, ToolState, ToolType } from '../main/ets/core/model/BrushTypes';
import { ToolRepository } from '../main/ets/data/RepositoryInterfaces';
import { EditorSettingsRepository } from '../main/ets/data/EditorSettingsStore';
import { EditorViewModel } from '../main/ets/ui/editor/EditorViewModel';

class FakeToolRepository implements ToolRepository {
  states: ToolState[] = [];
  toolbox: EditorToolboxState | null = null;
  failNextToolSave: boolean = false;

  async getToolStates(_ownerId: string): Promise<ToolState[]> {
    return this.cloneStates(this.states);
  }

  async saveToolState(state: ToolState): Promise<void> {
    if (this.failNextToolSave) {
      this.failNextToolSave = false;
      throw new Error('write failed');
    }
    const existing: number = this.indexOf(state.toolId);
    if (existing < 0) {
      this.states.push(this.cloneState(state));
    } else {
      this.states[existing] = this.cloneState(state);
    }
  }

  async saveToolStates(states: ToolState[]): Promise<void> {
    this.states = this.cloneStates(states);
  }

  async deleteToolState(toolId: string): Promise<void> {
    const remaining: ToolState[] = [];
    for (const state of this.states) {
      if (state.toolId !== toolId) {
        remaining.push(state);
      }
    }
    this.states = remaining;
  }

  async getToolboxState(_ownerId: string): Promise<EditorToolboxState | null> {
    if (this.toolbox === null) {
      return null;
    }
    return {
      ownerId: this.toolbox.ownerId,
      mostRecentlySelectedToolId: this.toolbox.mostRecentlySelectedToolId,
      previouslySelectedToolId: this.toolbox.previouslySelectedToolId,
    };
  }

  async saveToolboxState(state: EditorToolboxState): Promise<void> {
    this.toolbox = {
      ownerId: state.ownerId,
      mostRecentlySelectedToolId: state.mostRecentlySelectedToolId,
      previouslySelectedToolId: state.previouslySelectedToolId,
    };
  }

  private indexOf(toolId: string): number {
    for (let index: number = 0; index < this.states.length; index++) {
      if (this.states[index].toolId === toolId) {
        return index;
      }
    }
    return -1;
  }

  private cloneStates(states: ToolState[]): ToolState[] {
    const result: ToolState[] = [];
    for (const state of states) {
      result.push(this.cloneState(state));
    }
    return result;
  }

  private cloneState(state: ToolState): ToolState {
    return {
      toolId: state.toolId,
      trayOwnerId: state.trayOwnerId,
      toolType: state.toolType,
      trayIndex: state.trayIndex,
      brush: {
        brushStyle: state.brush.brushStyle,
        widthSize: state.brush.widthSize,
        color: state.brush.color,
        selectedWidthWellIndex: state.brush.selectedWidthWellIndex,
        selectedColorWellIndex: state.brush.selectedColorWellIndex,
      },
      selectionIsFreehand: state.selectionIsFreehand,
      eraserIsPartial: state.eraserIsPartial,
    };
  }
}

class FakeEditorSettingsRepository implements EditorSettingsRepository {
  enabled: boolean = true;
  failSave: boolean = false;

  async getShapeDetectionEnabled(): Promise<boolean> {
    return this.enabled;
  }

  async saveShapeDetectionEnabled(enabled: boolean): Promise<void> {
    if (this.failSave) {
      this.failSave = false;
      throw new Error('settings write failed');
    }
    this.enabled = enabled;
  }
}

export default function editorViewModelTest() {
  describe('EditorViewModel', () => {
    it('keeps pen and pencil settings independent and restores the active tool', 0, async () => {
      const repository = new FakeToolRepository();
      const first = new EditorViewModel();
      await first.initialize(repository);
      await first.setBrushColor(-65536, 2);
      await first.setBrushWidth(24, 11);
      await first.selectTool(ToolType.PENCIL);
      expect(first.brushColor).assertEqual(-16777216);
      expect(first.brushWidth).assertEqual(36);
      await first.setBrushColor(-16776961, 7);
      await first.setBrushStyle(BrushStyle.TAPER);
      await first.flushToolState();

      const restored = new EditorViewModel();
      await restored.initialize(repository);
      expect(restored.currentTool).assertEqual(ToolType.PENCIL);
      expect(restored.brushColor).assertEqual(-16776961);
      expect(restored.brushStyle).assertEqual(BrushStyle.TAPER);
      await restored.selectTool(ToolType.PEN);
      expect(restored.brushColor).assertEqual(-65536);
      expect(restored.brushWidth).assertEqual(24);
    });

    it('persists selection and eraser modes', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      await viewModel.selectTool(ToolType.SELECTION);
      await viewModel.setSelectionIsFreehand(true);
      await viewModel.selectTool(ToolType.PARTIAL_ERASER);
      expect(viewModel.currentTool).assertEqual(ToolType.PARTIAL_ERASER);

      const restored = new EditorViewModel();
      await restored.initialize(repository);
      expect(restored.currentTool).assertEqual(ToolType.PARTIAL_ERASER);
      expect(restored.eraserIsPartial).assertTrue();
      expect(restored.selectionIsFreehand).assertTrue();
    });

    it('rolls back an optimistic brush update when persistence fails', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const before: number = viewModel.brushColor;
      repository.failNextToolSave = true;
      const saved: boolean = await viewModel.setBrushColor(-65536, 2);
      expect(saved).assertFalse();
      expect(viewModel.brushColor).assertEqual(before);
    });

    it('loads and rolls back the original shape detection preference', 0, async () => {
      const repository = new FakeToolRepository();
      const settings = new FakeEditorSettingsRepository();
      settings.enabled = false;
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository, 'primary-editor', settings);
      expect(viewModel.shapeDetectionEnabled).assertFalse();
      settings.failSave = true;
      const saved: boolean = await viewModel.setShapeDetectionEnabled(true);
      expect(saved).assertFalse();
      expect(viewModel.shapeDetectionEnabled).assertFalse();
    });

    it('persists the shape detection preference for the next editor', 0, async () => {
      const repository = new FakeToolRepository();
      const settings = new FakeEditorSettingsRepository();
      const first = new EditorViewModel();
      await first.initialize(repository, 'primary-editor', settings);
      expect(first.shapeDetectionEnabled).assertTrue();
      expect(await first.setShapeDetectionEnabled(false)).assertTrue();
      const restored = new EditorViewModel();
      await restored.initialize(repository, 'primary-editor', settings);
      expect(restored.shapeDetectionEnabled).assertFalse();
    });
  });
}

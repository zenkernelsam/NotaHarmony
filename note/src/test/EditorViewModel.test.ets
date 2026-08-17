import { describe, it, expect } from '@ohos/hypium';
import { BrushStyle, EditorToolboxState, ToolState, ToolType } from '../main/ets/core/model/BrushTypes';
import { ToolRepository } from '../main/ets/data/RepositoryInterfaces';
import { EditorSettingsRepository } from '../main/ets/data/EditorSettingsStore';
import { EditorViewModel } from '../main/ets/ui/editor/EditorViewModel';

class DeferredSave {
  promise: Promise<void>;
  private resolvePromise: () => void = (): void => {
  };
  private rejectPromise: (error: Error) => void = (_error: Error): void => {
  };

  constructor() {
    this.promise = new Promise<void>((resolve: () => void,
      reject: (error: Error) => void): void => {
      this.resolvePromise = resolve;
      this.rejectPromise = reject;
    });
  }

  succeed(): void {
    this.resolvePromise();
  }

  fail(message: string = 'deferred write failed'): void {
    this.rejectPromise(new Error(message));
  }
}

class FakeToolRepository implements ToolRepository {
  states: ToolState[] = [];
  toolbox: EditorToolboxState | null = null;
  failNextToolSave: boolean = false;
  getToolStatesCalls: number = 0;
  toolSaveAttempts: ToolState[] = [];
  toolboxSaveAttempts: EditorToolboxState[] = [];
  private toolSaveGates: DeferredSave[] = [];
  private toolboxSaveGates: DeferredSave[] = [];

  deferNextToolSave(): DeferredSave {
    const gate = new DeferredSave();
    this.toolSaveGates.push(gate);
    return gate;
  }

  deferNextToolboxSave(): DeferredSave {
    const gate = new DeferredSave();
    this.toolboxSaveGates.push(gate);
    return gate;
  }

  async getToolStates(_ownerId: string): Promise<ToolState[]> {
    this.getToolStatesCalls++;
    return this.cloneStates(this.states);
  }

  async saveToolState(state: ToolState): Promise<void> {
    this.toolSaveAttempts.push(this.cloneState(state));
    const gate: DeferredSave | undefined = this.toolSaveGates.shift();
    if (gate !== undefined) {
      await gate.promise;
    }
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
    this.toolboxSaveAttempts.push(this.cloneToolbox(state));
    const gate: DeferredSave | undefined = this.toolboxSaveGates.shift();
    if (gate !== undefined) {
      await gate.promise;
    }
    this.toolbox = {
      ownerId: state.ownerId,
      mostRecentlySelectedToolId: state.mostRecentlySelectedToolId,
      previouslySelectedToolId: state.previouslySelectedToolId,
    };
  }

  colorFor(toolId: string): number {
    const index: number = this.indexOf(toolId);
    return index < 0 ? 0 : this.states[index].brush.color;
  }

  mostRecentToolId(): string {
    return this.toolbox === null ? '' : this.toolbox.mostRecentlySelectedToolId;
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

  private cloneToolbox(state: EditorToolboxState): EditorToolboxState {
    return {
      ownerId: state.ownerId,
      mostRecentlySelectedToolId: state.mostRecentlySelectedToolId,
      previouslySelectedToolId: state.previouslySelectedToolId,
    };
  }
}

class FakeEditorSettingsRepository implements EditorSettingsRepository {
  enabled: boolean = true;
  failSave: boolean = false;
  saveAttempts: boolean[] = [];
  private saveGates: DeferredSave[] = [];

  deferNextSave(): DeferredSave {
    const gate = new DeferredSave();
    this.saveGates.push(gate);
    return gate;
  }

  async getShapeDetectionEnabled(): Promise<boolean> {
    return this.enabled;
  }

  async saveShapeDetectionEnabled(enabled: boolean): Promise<void> {
    this.saveAttempts.push(enabled);
    const gate: DeferredSave | undefined = this.saveGates.shift();
    if (gate !== undefined) {
      await gate.promise;
    }
    if (this.failSave) {
      this.failSave = false;
      throw new Error('settings write failed');
    }
    this.enabled = enabled;
  }
}

async function waitForAttempts(readCount: () => number, expected: number): Promise<void> {
  for (let index: number = 0; index < 20 && readCount() < expected; index++) {
    await Promise.resolve();
  }
  const actual: number = readCount();
  if (actual < expected) {
    throw new Error(`expected ${expected} persistence attempts, received ${actual}`);
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

    it('restores the committed tool state when two optimistic writes both fail', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const firstGate: DeferredSave = repository.deferNextToolSave();
      const secondGate: DeferredSave = repository.deferNextToolSave();

      const firstSave: Promise<boolean> = viewModel.setBrushColor(-65536, 2);
      const secondSave: Promise<boolean> = viewModel.setBrushColor(-16776961, 7);
      expect(viewModel.brushColor).assertEqual(-16776961);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      firstGate.fail('first tool write failed');
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 2);
      secondGate.fail('second tool write failed');

      expect(await firstSave).assertFalse();
      expect(await secondSave).assertFalse();
      expect(viewModel.brushColor).assertEqual(-16777216);
      expect(repository.colorFor('pen')).assertEqual(-16777216);
    });

    it('keeps the newer tool state when the first write fails and the second succeeds', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const firstGate: DeferredSave = repository.deferNextToolSave();
      const secondGate: DeferredSave = repository.deferNextToolSave();

      const firstSave: Promise<boolean> = viewModel.setBrushColor(-65536, 2);
      const secondSave: Promise<boolean> = viewModel.setBrushColor(-16776961, 7);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      firstGate.fail('first tool write failed');
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 2);
      secondGate.succeed();

      expect(await firstSave).assertFalse();
      expect(await secondSave).assertTrue();
      expect(viewModel.brushColor).assertEqual(-16776961);
      expect(repository.colorFor('pen')).assertEqual(-16776961);
    });

    it('rolls back to the first committed tool state when only the second write fails', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const firstGate: DeferredSave = repository.deferNextToolSave();
      const secondGate: DeferredSave = repository.deferNextToolSave();

      const firstSave: Promise<boolean> = viewModel.setBrushColor(-65536, 2);
      const secondSave: Promise<boolean> = viewModel.setBrushColor(-16776961, 7);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      firstGate.succeed();
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 2);
      secondGate.fail('second tool write failed');

      expect(await firstSave).assertTrue();
      expect(await secondSave).assertFalse();
      expect(viewModel.brushColor).assertEqual(-65536);
      expect(repository.colorFor('pen')).assertEqual(-65536);
    });

    it('waits for the prior save chain before reinitializing from the repository', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const saveGate: DeferredSave = repository.deferNextToolSave();

      const pendingSave: Promise<boolean> = viewModel.setBrushColor(-65536, 2);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      const reinitialize: Promise<boolean> = viewModel.initialize(repository);
      await Promise.resolve();
      expect(viewModel.toolStateLoading).assertTrue();
      expect(repository.getToolStatesCalls).assertEqual(1);

      saveGate.succeed();
      expect(await pendingSave).assertTrue();
      expect(await reinitialize).assertTrue();
      expect(repository.getToolStatesCalls).assertEqual(2);
      expect(viewModel.brushColor).assertEqual(-65536);
      expect(repository.colorFor('pen')).assertEqual(-65536);
    });

    it('restores the committed tool selection after consecutive toolbox failures', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const firstGate: DeferredSave = repository.deferNextToolboxSave();
      const secondGate: DeferredSave = repository.deferNextToolboxSave();

      const firstSelection: Promise<boolean> = viewModel.selectTool(ToolType.PENCIL);
      const secondSelection: Promise<boolean> = viewModel.selectTool(ToolType.HIGHLIGHTER);
      await waitForAttempts((): number => repository.toolboxSaveAttempts.length, 2);
      firstGate.fail('first toolbox write failed');
      await waitForAttempts((): number => repository.toolboxSaveAttempts.length, 3);
      secondGate.fail('second toolbox write failed');

      expect(await firstSelection).assertFalse();
      expect(await secondSelection).assertFalse();
      expect(viewModel.currentTool).assertEqual(ToolType.PEN);
      expect(repository.mostRecentToolId()).assertEqual('pen');
    });

    it('rolls back to the first committed selection when only the newer toolbox write fails', 0,
      async () => {
        const repository = new FakeToolRepository();
        const viewModel = new EditorViewModel();
        await viewModel.initialize(repository);
        const firstGate: DeferredSave = repository.deferNextToolboxSave();
        const secondGate: DeferredSave = repository.deferNextToolboxSave();

        const firstSelection: Promise<boolean> = viewModel.selectTool(ToolType.PENCIL);
        const secondSelection: Promise<boolean> = viewModel.selectTool(ToolType.HIGHLIGHTER);
        await waitForAttempts((): number => repository.toolboxSaveAttempts.length, 2);
        firstGate.succeed();
        await waitForAttempts((): number => repository.toolboxSaveAttempts.length, 3);
        secondGate.fail('second toolbox write failed');

        expect(await firstSelection).assertTrue();
        expect(await secondSelection).assertFalse();
        expect(viewModel.currentTool).assertEqual(ToolType.PENCIL);
        expect(repository.mostRecentToolId()).assertEqual('pencil');
      });

    it('does not let a failed eraser-mode write overwrite a later tool selection', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const eraserGate: DeferredSave = repository.deferNextToolSave();

      const eraserSelection: Promise<boolean> = viewModel.selectTool(ToolType.PARTIAL_ERASER);
      const laterSelection: Promise<boolean> = viewModel.selectTool(ToolType.PENCIL);
      expect(viewModel.currentTool).assertEqual(ToolType.PENCIL);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      eraserGate.fail('eraser mode write failed');

      expect(await eraserSelection).assertFalse();
      expect(await laterSelection).assertTrue();
      expect(viewModel.currentTool).assertEqual(ToolType.PENCIL);
      expect(repository.mostRecentToolId()).assertEqual('pencil');
    });

    it('does not let a successful late eraser-mode save reactivate the old selection', 0, async () => {
      const repository = new FakeToolRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository);
      const eraserGate: DeferredSave = repository.deferNextToolSave();

      const eraserSelection: Promise<boolean> = viewModel.selectTool(ToolType.PARTIAL_ERASER);
      const laterSelection: Promise<boolean> = viewModel.selectTool(ToolType.PENCIL);
      await waitForAttempts((): number => repository.toolSaveAttempts.length, 1);
      eraserGate.succeed();

      expect(await eraserSelection).assertTrue();
      expect(await laterSelection).assertTrue();
      expect(viewModel.currentTool).assertEqual(ToolType.PENCIL);
      expect(repository.mostRecentToolId()).assertEqual('pencil');
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

    it('restores the committed shape preference when two queued writes both fail', 0, async () => {
      const repository = new FakeToolRepository();
      const settings = new FakeEditorSettingsRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository, 'primary-editor', settings);
      const firstGate: DeferredSave = settings.deferNextSave();
      const secondGate: DeferredSave = settings.deferNextSave();

      const firstSave: Promise<boolean> = viewModel.setShapeDetectionEnabled(false);
      const secondSave: Promise<boolean> = viewModel.setShapeDetectionEnabled(true);
      await waitForAttempts((): number => settings.saveAttempts.length, 1);
      firstGate.fail('first settings write failed');
      await waitForAttempts((): number => settings.saveAttempts.length, 2);
      secondGate.fail('second settings write failed');

      expect(await firstSave).assertFalse();
      expect(await secondSave).assertFalse();
      expect(viewModel.shapeDetectionEnabled).assertTrue();
      expect(settings.enabled).assertTrue();
    });

    it('rolls back shape preference to the first successful queued write', 0, async () => {
      const repository = new FakeToolRepository();
      const settings = new FakeEditorSettingsRepository();
      const viewModel = new EditorViewModel();
      await viewModel.initialize(repository, 'primary-editor', settings);
      const firstGate: DeferredSave = settings.deferNextSave();
      const secondGate: DeferredSave = settings.deferNextSave();

      const firstSave: Promise<boolean> = viewModel.setShapeDetectionEnabled(false);
      const secondSave: Promise<boolean> = viewModel.setShapeDetectionEnabled(true);
      await waitForAttempts((): number => settings.saveAttempts.length, 1);
      firstGate.succeed();
      await waitForAttempts((): number => settings.saveAttempts.length, 2);
      secondGate.fail('second settings write failed');

      expect(await firstSave).assertTrue();
      expect(await secondSave).assertFalse();
      expect(viewModel.shapeDetectionEnabled).assertFalse();
      expect(settings.enabled).assertFalse();
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

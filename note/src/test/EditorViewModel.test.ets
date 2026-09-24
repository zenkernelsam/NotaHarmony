import { describe, it, expect } from '@ohos/hypium';
import {
  BrushStyle, EditorToolboxState, EditorTray, ToolState, ToolType,
} from '../main/ets/core/model/BrushTypes';
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
    const removed: ToolState | null = this.indexOf(toolId) < 0 ? null : this.states[this.indexOf(toolId)];
    const remaining: ToolState[] = [];
    for (const state of this.states) {
      if (state.toolId !== toolId) {
        remaining.push(state);
      }
    }
    this.states = remaining;
    if (removed !== null) {
      let index: number = 0;
      for (const state of this.states) {
        if (state.trayType === removed.trayType) {
          state.trayIndex = index;
          index++;
        }
      }
    }
  }

  trays: EditorTray[] = [];

  async getTrays(ownerId: string): Promise<EditorTray[]> {
    const result: EditorTray[] = [];
    for (const tray of this.trays) {
      if (tray.toolboxOwnerId === ownerId) {
        result.push({
          trayId: tray.trayId,
          trayType: tray.trayType,
          toolboxOwnerId: tray.toolboxOwnerId,
          lastUsedToolId: tray.lastUsedToolId,
        });
      }
    }
    return result;
  }

  async ensureTrays(ownerId: string): Promise<void> {
    for (let trayId: number = 0; trayId <= 2; trayId++) {
      if (!this.hasTray(ownerId, trayId)) {
        this.trays.push({
          trayId: trayId,
          trayType: trayId,
          toolboxOwnerId: ownerId,
          lastUsedToolId: null,
        });
      }
    }
  }

  async setTrayLastUsedTool(trayType: number, ownerId: string, toolId: string): Promise<void> {
    for (const tray of this.trays) {
      if (tray.toolboxOwnerId === ownerId && tray.trayType === trayType) {
        tray.lastUsedToolId = toolId;
      }
    }
  }

  // In-memory mirror of i8f.a: reindex the source tray, insert into the
  // destination tray at a clamped index, reindex the destination.
  async moveToolToTray(toolId: string, destTrayType: number, insertIndex: number): Promise<void> {
    const movedIndex: number = this.indexOf(toolId);
    if (movedIndex < 0) {
      return;
    }
    const moved: ToolState = this.states[movedIndex];
    const sourceTray: number = moved.trayType;
    if (sourceTray !== destTrayType) {
      let index: number = 0;
      for (const state of this.states) {
        if (state.trayType === sourceTray && state.toolId !== toolId) {
          state.trayIndex = index;
          index++;
        }
      }
    }
    const destTools: ToolState[] = [];
    for (const state of this.states) {
      if (state.trayType === destTrayType && state.toolId !== toolId) {
        destTools.push(state);
      }
    }
    const clamped: number = Math.max(0, Math.min(insertIndex, destTools.length));
    destTools.splice(clamped, 0, moved);
    for (let index: number = 0; index < destTools.length; index++) {
      destTools[index].trayType = destTrayType;
      destTools[index].trayIndex = index;
    }
    this.states.sort((a: ToolState, b: ToolState): number =>
      a.trayType - b.trayType || a.trayIndex - b.trayIndex);
  }

  async insertToolStateAt(state: ToolState): Promise<void> {
    for (const existing of this.states) {
      if (existing.trayType === state.trayType && existing.trayIndex >= state.trayIndex) {
        existing.trayIndex += 1;
      }
    }
    this.states.push(this.cloneState(state));
    this.states.sort((a: ToolState, b: ToolState): number =>
      a.trayType - b.trayType || a.trayIndex - b.trayIndex);
  }

  async deleteAllToolStates(ownerId: string): Promise<void> {
    const remaining: ToolState[] = [];
    for (const state of this.states) {
      if (state.trayOwnerId !== ownerId) {
        remaining.push(state);
      }
    }
    this.states = remaining;
    const remainingTrays: EditorTray[] = [];
    for (const tray of this.trays) {
      if (tray.toolboxOwnerId !== ownerId) {
        remainingTrays.push(tray);
      }
    }
    this.trays = remainingTrays;
    if (this.toolbox !== null && this.toolbox.ownerId === ownerId) {
      this.toolbox = null;
    }
  }

  private hasTray(ownerId: string, trayId: number): boolean {
    for (const tray of this.trays) {
      if (tray.toolboxOwnerId === ownerId && tray.trayId === trayId) {
        return true;
      }
    }
    return false;
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

  favoriteWells: Map<number, number[]> = new Map<number, number[]>();
  widthWellMap: Map<number, number[]> = new Map<number, number[]>();
  recentColorList: number[] = [];

  async getFavoriteColors(toolType: number): Promise<number[]> {
    const wells: number[] | undefined = this.favoriteWells.get(toolType);
    return wells === undefined ? [] : wells.slice();
  }

  async setFavoriteColor(toolType: number, trayIndex: number, color: number): Promise<void> {
    const wells: number[] = this.favoriteWells.get(toolType) ?? [];
    while (wells.length <= trayIndex) {
      wells.push(color);
    }
    wells[trayIndex] = color;
    this.favoriteWells.set(toolType, wells);
  }

  async removeFavoriteColor(toolType: number, trayIndex: number): Promise<void> {
    const wells: number[] | undefined = this.favoriteWells.get(toolType);
    if (wells === undefined || trayIndex < 0 || trayIndex >= wells.length) {
      return;
    }
    wells.splice(trayIndex, 1);
  }

  async getWidthWells(toolType: number): Promise<number[]> {
    const wells: number[] | undefined = this.widthWellMap.get(toolType);
    return wells === undefined ? [] : wells.slice();
  }

  async setWidthWell(toolType: number, trayIndex: number, width: number): Promise<void> {
    const wells: number[] = this.widthWellMap.get(toolType) ?? [];
    while (wells.length <= trayIndex) {
      wells.push(width);
    }
    wells[trayIndex] = width;
    this.widthWellMap.set(toolType, wells);
  }

  async removeWidthWell(toolType: number, trayIndex: number): Promise<void> {
    const wells: number[] | undefined = this.widthWellMap.get(toolType);
    if (wells === undefined || trayIndex < 0 || trayIndex >= wells.length) {
      return;
    }
    wells.splice(trayIndex, 1);
  }

  async getRecentColors(): Promise<number[]> {
    return this.recentColorList.slice();
  }

  async recordRecentColor(color: number): Promise<void> {
    const existing: number = this.recentColorList.indexOf(color);
    if (existing >= 0) {
      this.recentColorList.splice(existing, 1);
    } else if (this.recentColorList.length >= 7) {
      this.recentColorList.splice(6, this.recentColorList.length - 6);
    }
    this.recentColorList.unshift(color);
  }

  async seedDefaultToolWells(): Promise<void> {
    if (this.favoriteWells.size === 0) {
      this.favoriteWells.set(ToolType.PEN, [-16777216, -15260469, -2011583]);
      this.favoriteWells.set(ToolType.PENCIL, [-16777216, -15260469, -2011583]);
      this.favoriteWells.set(ToolType.HIGHLIGHTER, [-172, -4391597, -1428530]);
      this.favoriteWells.set(ToolType.REVIEW, [-1706497, -672330, -6303021, -11872, -2238485]);
    }
    if (this.widthWellMap.size === 0) {
      this.widthWellMap.set(ToolType.PEN, [1.0, 2.0, 4.0]);
      this.widthWellMap.set(ToolType.PENCIL, [1.5, 3.0, 5.0]);
      this.widthWellMap.set(ToolType.HIGHLIGHTER, [20.0, 15.0, 10.0]);
      this.widthWellMap.set(ToolType.WHOLE_ERASER, [4.0, 7.5, 15.0]);
      this.widthWellMap.set(ToolType.REVIEW, [12.0, 36.0, 64.0]);
    }
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
      trayType: state.trayType,
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

  async getKeepDeviceAwake(): Promise<boolean> {
    return false;
  }

  async saveKeepDeviceAwake(_enabled: boolean): Promise<void> {
  }

  async getHideStatusBar(): Promise<boolean> {
    return false;
  }

  async saveHideStatusBar(_enabled: boolean): Promise<void> {
  }

  async getHideNavigationBar(): Promise<boolean> {
    return false;
  }

  async saveHideNavigationBar(_enabled: boolean): Promise<void> {
  }

  async getNoteViewNightMode(): Promise<boolean> {
    return false;
  }

  async saveNoteViewNightMode(_enabled: boolean): Promise<void> {
  }

  async getAutoDeselectEraser(): Promise<boolean> {
    return false;
  }

  async saveAutoDeselectEraser(_enabled: boolean): Promise<void> {
  }

  async getPalmDetectionEnabled(): Promise<boolean> {
    return true;
  }

  async savePalmDetectionEnabled(_enabled: boolean): Promise<void> {
  }

  async getStraightLinesEnabled(): Promise<boolean> {
    return true;
  }

  async saveStraightLinesEnabled(_enabled: boolean): Promise<void> {
  }

  async getRulerUnits(): Promise<string> {
    return 'Imperial';
  }

  async saveRulerUnits(_units: string): Promise<void> {
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

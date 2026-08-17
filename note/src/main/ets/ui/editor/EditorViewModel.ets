import {
  BrushStyle, EditorToolboxState, ToolState, ToolType, brushStyleToInkStyle,
} from '../../core/model/BrushTypes';
import { RenderSpec } from '../../core/model/StrokeTypes';
import { ToolRepository } from '../../data/RepositoryInterfaces';
import { EditorSettingsRepository } from '../../data/EditorSettingsStore';

const DEFAULT_TOOLBOX_OWNER: string = 'primary-editor';

@Observed
export class EditorViewModel {
  currentTool: ToolType = ToolType.PEN;
  brushStyle: BrushStyle = BrushStyle.MONO;
  brushColor: number = -16777216;
  brushWidth: number = 36.0;
  eraserIsPartial: boolean = false;
  selectionIsFreehand: boolean = false;
  showColorPicker: boolean = false;
  showWidthSlider: boolean = false;
  shapeDetectionEnabled: boolean = true;
  toolStateLoading: boolean = true;
  toolStateLoadFailed: boolean = false;
  onPersistenceError: (message: string) => void = (_message: string): void => {
  };

  private repository: ToolRepository | null = null;
  private settingsRepository: EditorSettingsRepository | null = null;
  private ownerId: string = DEFAULT_TOOLBOX_OWNER;
  private states: ToolState[] = [];
  private activeToolId: string = 'pen';
  private previousToolId: string = 'pen';
  private committedStates: Map<string, ToolState> = new Map<string, ToolState>();
  private committedToolbox: EditorToolboxState | null = null;
  private stateVersions: Map<string, number> = new Map<string, number>();
  private selectionVersion: number = 0;
  private committedShapeDetectionEnabled: boolean = true;
  private shapeDetectionVersion: number = 0;
  private saveChain: Promise<void> = Promise.resolve();

  async initialize(repository: ToolRepository, ownerId: string = DEFAULT_TOOLBOX_OWNER,
    settingsRepository: EditorSettingsRepository | null = null): Promise<boolean> {
    this.toolStateLoading = true;
    await this.saveChain;
    this.repository = repository;
    this.settingsRepository = settingsRepository;
    this.ownerId = ownerId;
    this.toolStateLoadFailed = false;
    this.stateVersions.clear();
    this.committedStates.clear();
    this.committedToolbox = null;
    this.selectionVersion = 0;
    this.shapeDetectionEnabled = true;
    this.committedShapeDetectionEnabled = true;
    this.shapeDetectionVersion = 0;
    const defaults: ToolState[] = this.createDefaultStates(ownerId);
    try {
      const loaded: ToolState[] = await repository.getToolStates(ownerId);
      const merged: ToolState[] = [];
      const missing: ToolState[] = [];
      for (const fallback of defaults) {
        const stored: ToolState | null = this.findFirstType(loaded, fallback.toolType);
        if (stored === null) {
          merged.push(this.cloneState(fallback));
          missing.push(this.cloneState(fallback));
        } else {
          merged.push(this.sanitizeState(stored, fallback));
        }
      }
      this.states = merged;
      if (loaded.length === 0) {
        await repository.saveToolStates(this.cloneStates(this.states));
      } else {
        for (const state of missing) {
          await repository.saveToolState(this.cloneState(state));
        }
      }
      this.replaceCommittedStates(this.states);

      const toolbox: EditorToolboxState | null = await repository.getToolboxState(ownerId);
      const fallbackPen: ToolState = this.requireState(ToolType.PEN);
      if (toolbox !== null && this.findById(toolbox.mostRecentlySelectedToolId) !== null) {
        this.activeToolId = toolbox.mostRecentlySelectedToolId;
        this.previousToolId = this.findById(toolbox.previouslySelectedToolId) !== null ?
          toolbox.previouslySelectedToolId : this.activeToolId;
      } else {
        this.activeToolId = fallbackPen.toolId;
        this.previousToolId = fallbackPen.toolId;
        await repository.saveToolboxState(this.toolboxSnapshot());
      }
      this.committedToolbox = this.cloneToolboxState(this.toolboxSnapshot());
      this.applyActiveState();
      if (settingsRepository !== null) {
        try {
          this.shapeDetectionEnabled = await settingsRepository.getShapeDetectionEnabled();
          this.committedShapeDetectionEnabled = this.shapeDetectionEnabled;
        } catch (settingsError) {
          this.onPersistenceError(`Editor settings could not be loaded: ${JSON.stringify(settingsError)}`);
        }
      }
      this.toolStateLoading = false;
      return true;
    } catch (e) {
      this.states = defaults;
      this.replaceCommittedStates(this.states);
      this.activeToolId = 'pen';
      this.previousToolId = 'pen';
      this.committedToolbox = this.cloneToolboxState(this.toolboxSnapshot());
      this.applyActiveState();
      this.toolStateLoading = false;
      this.toolStateLoadFailed = true;
      this.onPersistenceError(`Tool settings could not be loaded: ${JSON.stringify(e)}`);
      return false;
    }
  }

  getRenderSpec(): RenderSpec {
    return {
      color: this.brushColor,
      brushWidth: this.brushWidth,
      inkStyle: brushStyleToInkStyle(this.brushStyle),
      isHighlighter: this.currentTool === ToolType.HIGHLIGHTER,
      isPencil: this.currentTool === ToolType.PENCIL,
    };
  }

  async selectTool(tool: ToolType): Promise<boolean> {
    if (this.toolStateLoading) {
      return false;
    }
    const requestedType: ToolType = this.canonicalType(tool);
    const target: ToolState | null = this.findFirstType(this.states, requestedType);
    if (target === null) {
      return false;
    }
    this.selectionVersion++;
    const version: number = this.selectionVersion;
    this.previousToolId = this.activeToolId;
    this.activeToolId = target.toolId;
    if (requestedType === ToolType.WHOLE_ERASER) {
      const modeSaved: boolean = await this.setEraserIsPartial(tool === ToolType.PARTIAL_ERASER);
      if (!modeSaved) {
        if (this.selectionVersion === version) {
          this.restoreCommittedToolbox();
        }
        return false;
      }
      if (this.selectionVersion !== version) {
        return true;
      }
    }
    this.applyActiveState();
    this.showColorPicker = false;
    this.showWidthSlider = false;
    const repository: ToolRepository | null = this.repository;
    const snapshot: EditorToolboxState = this.toolboxSnapshot();
    if (repository === null) {
      this.committedToolbox = this.cloneToolboxState(snapshot);
      return true;
    }
    try {
      await this.enqueueSave(async (): Promise<void> => repository.saveToolboxState(snapshot));
      this.committedToolbox = this.cloneToolboxState(snapshot);
      return true;
    } catch (e) {
      if (this.selectionVersion === version) {
        this.restoreCommittedToolbox();
      }
      this.onPersistenceError(`Tool selection was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async setBrushColor(color: number, selectedWellIndex: number = 0): Promise<boolean> {
    return this.updateActiveState((state: ToolState): void => {
      state.brush.color = color;
      state.brush.selectedColorWellIndex = selectedWellIndex;
    });
  }

  async setBrushWidth(width: number, selectedWellIndex: number = 0): Promise<boolean> {
    const bounded: number = Math.max(2, Math.min(100, width));
    return this.updateActiveState((state: ToolState): void => {
      state.brush.widthSize = bounded;
      state.brush.selectedWidthWellIndex = selectedWellIndex;
    });
  }

  async setBrushStyle(style: BrushStyle): Promise<boolean> {
    return this.updateActiveState((state: ToolState): void => {
      state.brush.brushStyle = style;
    });
  }

  async setSelectionIsFreehand(isFreehand: boolean): Promise<boolean> {
    const state: ToolState = this.requireState(ToolType.SELECTION);
    return this.updateState(state.toolId, (updated: ToolState): void => {
      updated.selectionIsFreehand = isFreehand;
    });
  }

  async setEraserIsPartial(isPartial: boolean): Promise<boolean> {
    const state: ToolState = this.requireState(ToolType.WHOLE_ERASER);
    return this.updateState(state.toolId, (updated: ToolState): void => {
      updated.eraserIsPartial = isPartial;
    });
  }

  async setShapeDetectionEnabled(enabled: boolean): Promise<boolean> {
    this.shapeDetectionVersion++;
    const version: number = this.shapeDetectionVersion;
    this.shapeDetectionEnabled = enabled;
    const repository: EditorSettingsRepository | null = this.settingsRepository;
    if (repository === null) {
      this.committedShapeDetectionEnabled = enabled;
      return true;
    }
    try {
      await this.enqueueSave(async (): Promise<void> => repository.saveShapeDetectionEnabled(enabled));
      this.committedShapeDetectionEnabled = enabled;
      return true;
    } catch (e) {
      if (this.shapeDetectionVersion === version) {
        this.shapeDetectionEnabled = this.committedShapeDetectionEnabled;
      }
      this.onPersistenceError(`Shape detection setting was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async flushToolState(): Promise<void> {
    await this.saveChain;
  }

  isEraserActive(): boolean {
    return this.currentTool === ToolType.PARTIAL_ERASER || this.currentTool === ToolType.WHOLE_ERASER;
  }

  isSelectionActive(): boolean {
    return this.currentTool === ToolType.SELECTION;
  }

  supportsBrushControls(): boolean {
    return this.currentTool === ToolType.PEN || this.currentTool === ToolType.PENCIL ||
      this.currentTool === ToolType.HIGHLIGHTER;
  }

  colorToHex(argb: number): string {
    const r: number = (argb >>> 16) & 0xFF;
    const g: number = (argb >>> 8) & 0xFF;
    const b: number = argb & 0xFF;
    const toHex = (v: number): string => {
      const s: string = v.toString(16);
      return s.length === 1 ? '0' + s : s;
    };
    return '#' + toHex(r) + toHex(g) + toHex(b);
  }

  private async updateActiveState(mutate: (state: ToolState) => void): Promise<boolean> {
    if (!this.supportsBrushControls()) {
      return false;
    }
    return this.updateState(this.activeToolId, mutate);
  }

  private async updateState(toolId: string, mutate: (state: ToolState) => void): Promise<boolean> {
    const index: number = this.indexById(toolId);
    if (index < 0) {
      return false;
    }
    const updated: ToolState = this.cloneState(this.states[index]);
    mutate(updated);
    this.states[index] = updated;
    const version: number = (this.stateVersions.get(toolId) ?? 0) + 1;
    this.stateVersions.set(toolId, version);
    if (toolId === this.activeToolId) {
      this.applyActiveState();
    }
    const repository: ToolRepository | null = this.repository;
    if (repository === null) {
      this.committedStates.set(toolId, this.cloneState(updated));
      return true;
    }
    try {
      await this.enqueueSave(async (): Promise<void> => repository.saveToolState(this.cloneState(updated)));
      this.committedStates.set(toolId, this.cloneState(updated));
      return true;
    } catch (e) {
      if (this.stateVersions.get(toolId) === version) {
        const committed: ToolState | undefined = this.committedStates.get(toolId);
        if (committed !== undefined) {
          this.states[index] = this.cloneState(committed);
          if (toolId === this.activeToolId) {
            this.applyActiveState();
          }
        }
      }
      this.onPersistenceError(`Tool setting was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  private enqueueSave(operation: () => Promise<void>): Promise<void> {
    const job: Promise<void> = this.saveChain.then(operation);
    this.saveChain = job.catch((_error: Object): void => {
    });
    return job;
  }

  private applyActiveState(): void {
    const state: ToolState | null = this.findById(this.activeToolId);
    if (state === null) {
      return;
    }
    this.brushColor = state.brush.color;
    this.brushWidth = state.brush.widthSize;
    this.brushStyle = state.brush.brushStyle;
    this.selectionIsFreehand = this.requireState(ToolType.SELECTION).selectionIsFreehand;
    this.eraserIsPartial = this.requireState(ToolType.WHOLE_ERASER).eraserIsPartial;
    this.currentTool = state.toolType === ToolType.WHOLE_ERASER && this.eraserIsPartial ?
      ToolType.PARTIAL_ERASER : state.toolType;
  }

  private toolboxSnapshot(): EditorToolboxState {
    return {
      ownerId: this.ownerId,
      mostRecentlySelectedToolId: this.activeToolId,
      previouslySelectedToolId: this.previousToolId,
    };
  }

  private restoreCommittedToolbox(): void {
    const committed: EditorToolboxState | null = this.committedToolbox;
    if (committed === null || this.findById(committed.mostRecentlySelectedToolId) === null) {
      return;
    }
    this.activeToolId = committed.mostRecentlySelectedToolId;
    this.previousToolId = this.findById(committed.previouslySelectedToolId) === null ?
      this.activeToolId : committed.previouslySelectedToolId;
    this.applyActiveState();
  }

  private replaceCommittedStates(states: ToolState[]): void {
    this.committedStates.clear();
    for (const state of states) {
      this.committedStates.set(state.toolId, this.cloneState(state));
    }
  }

  private cloneToolboxState(state: EditorToolboxState): EditorToolboxState {
    return {
      ownerId: state.ownerId,
      mostRecentlySelectedToolId: state.mostRecentlySelectedToolId,
      previouslySelectedToolId: state.previouslySelectedToolId,
    };
  }

  private canonicalType(tool: ToolType): ToolType {
    return tool === ToolType.PARTIAL_ERASER ? ToolType.WHOLE_ERASER : tool;
  }

  private requireState(type: ToolType): ToolState {
    const state: ToolState | null = this.findFirstType(this.states, type);
    if (state === null) {
      throw new Error(`Missing editor tool state ${type}`);
    }
    return state;
  }

  private findFirstType(states: ToolState[], type: ToolType): ToolState | null {
    for (const state of states) {
      if (state.toolType === type) {
        return state;
      }
    }
    return null;
  }

  private findById(toolId: string): ToolState | null {
    const index: number = this.indexById(toolId);
    return index < 0 ? null : this.states[index];
  }

  private indexById(toolId: string): number {
    for (let index: number = 0; index < this.states.length; index++) {
      if (this.states[index].toolId === toolId) {
        return index;
      }
    }
    return -1;
  }

  private sanitizeState(stored: ToolState, fallback: ToolState): ToolState {
    const state: ToolState = this.cloneState(stored);
    state.trayOwnerId = this.ownerId;
    if (state.brush.widthSize < 2 || state.brush.widthSize > 100) {
      state.brush.widthSize = fallback.brush.widthSize;
    }
    if (state.brush.brushStyle < BrushStyle.MONO || state.brush.brushStyle > BrushStyle.DOT) {
      state.brush.brushStyle = fallback.brush.brushStyle;
    }
    return state;
  }

  private createDefaultStates(ownerId: string): ToolState[] {
    return [
      this.createState('pen', ownerId, ToolType.PEN, 0, -16777216, 36, BrushStyle.MONO),
      this.createState('pencil', ownerId, ToolType.PENCIL, 1, -16777216, 36, BrushStyle.MONO),
      this.createState('highlighter', ownerId, ToolType.HIGHLIGHTER, 2, -256, 36, BrushStyle.MONO),
      this.createState('eraser', ownerId, ToolType.WHOLE_ERASER, 3, -16777216, 20, BrushStyle.MONO),
      this.createState('selection', ownerId, ToolType.SELECTION, 4, -16777216, 36, BrushStyle.MONO),
      this.createState('text', ownerId, ToolType.DEFAULT, 5, -16777216, 36, BrushStyle.MONO),
    ];
  }

  private createState(toolId: string, ownerId: string, toolType: ToolType, trayIndex: number,
    color: number, width: number, style: BrushStyle): ToolState {
    return {
      toolId: toolId,
      trayOwnerId: ownerId,
      toolType: toolType,
      trayIndex: trayIndex,
      brush: {
        brushStyle: style,
        widthSize: width,
        color: color,
        selectedWidthWellIndex: 0,
        selectedColorWellIndex: 0,
      },
      selectionIsFreehand: false,
      eraserIsPartial: false,
    };
  }

  private cloneStates(states: ToolState[]): ToolState[] {
    const copies: ToolState[] = [];
    for (const state of states) {
      copies.push(this.cloneState(state));
    }
    return copies;
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

import {
  BrushStyle, EditorToolboxState, ToolState, ToolType, brushStyleToInkStyle,
  TRAY_TYPE_PRIMARY, TRAY_TYPE_SECONDARY, TRAY_TYPE_HIDDEN, MAX_PRIMARY_TOOLS,
} from '../../core/model/BrushTypes';
import { RenderSpec, TapePattern } from '../../core/model/StrokeTypes';
import { ToolRepository } from '../../data/RepositoryInterfaces';
import { EditorSettingsRepository } from '../../data/EditorSettingsStore';

const DEFAULT_TOOLBOX_OWNER: string = 'primary-editor';

@Observed
export class EditorViewModel {
  currentTool: ToolType = ToolType.PEN;
  // 原版 g39.a() 标记的等价物之一：r5f 手势面切换 → Q.a() 打点；
  // 200ms 内长按粘贴菜单（yqa/g39.b()）被抑制。
  toolChangedAt: number = 0;
  brushStyle: BrushStyle = BrushStyle.MONO;
  brushColor: number = -16777216;
  brushWidth: number = 36.0;
  eraserIsPartial: boolean = false;
  selectionIsFreehand: boolean = false;
  favoriteColors: number[] = [];
  recentColors: number[] = [];
  widthWells: number[] = [];
  showColorPicker: boolean = false;
  showWidthSlider: boolean = false;
  // 原版 lu7/i8f.k（ADR-0646）：eyedropper 激活态——色彩面板内开启后画布
  // 触摸转为取样；提交（q5 case5）或显式关闭（i3 case12）即 lu7.a(...,6)
  // 复位 enabled；工具切换/面板关闭同样失效。
  eyedropperActive: boolean = false;
  // lu7.b 的目标上下文：true=选区颜色（色彩面板 selectionMode），
  // false=当前工具 brushColor。
  eyedropperForSelection: boolean = false;
  shapeDetectionEnabled: boolean = true;
  // 原版 x22 case 3 / i8f.d：autoDeselectEraser——擦除后工具栏自动切回
  // 上一个工具（epi.c 取 previouslySelected）。
  autoDeselectEraser: boolean = false;
  // 原版 x22 case 2 / o59.l：palmDetectionEnabled——笔迹进行中忽略手掌触摸。
  palmDetectionEnabled: boolean = true;
  // 原版 x22 case 0 / o59.j：straightLinesEnabled——按住自动拉直线条。
  straightLinesEnabled: boolean = true;
  // 原版 cu6/bu6：laser_preferences.show_tail 缺省 true——激光笔拖尾开关。
  laserShowTail: boolean = true;
  // 原版 w31.f (BrushState.tapePattern)：REVIEW 工具的当前胶带图案，
  // rz1:1075 缺省 0 = STRIPES；仅 REVIEW 激活时有意义。
  activeTapePattern: TapePattern = TapePattern.STRIPES;
  toolStateLoading: boolean = true;
  toolStateLoadFailed: boolean = false;
  // Structural mirror of `states` reassigned on every tray mutation so @ObjectLink
  // observers re-render the tool list (the toolbar binds to this, not `states`).
  toolStates: ToolState[] = [];
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
  private initializationGate: (() => boolean) | null = null;

  async initialize(repository: ToolRepository, ownerId: string = DEFAULT_TOOLBOX_OWNER,
    settingsRepository: EditorSettingsRepository | null = null,
    isCurrent: (() => boolean) | null = null): Promise<boolean> {
    this.toolStateLoading = true;
    this.initializationGate = isCurrent;
    await this.saveChain;
    if (!this.isInitializationCurrent()) {
      return false;
    }
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
      // gr7/ba8 parity: the three trays (Primary/Secondary/Hidden) exist per owner.
      await repository.ensureTrays(ownerId);
      const loaded: ToolState[] = await repository.getToolStates(ownerId);
      if (!this.isInitializationCurrent()) {
        return false;
      }
      const merged: ToolState[] = [];
      for (const stored of loaded) {
        const fallback: ToolState | null = this.findFirstType(defaults, stored.toolType);
        merged.push(this.sanitizeState(stored, fallback === null ? stored : fallback));
      }
      // Original invariant: every default tool type is always present somewhere
      // (x7f refuses to delete the sole visible instance), so missing types are
      // backfilled at the Primary tray tail. Hidden/duplicated rows pass through.
      const missing: ToolState[] = [];
      let primaryCount: number = this.countTrayType(merged, TRAY_TYPE_PRIMARY);
      for (const fallback of defaults) {
        if (this.findFirstType(merged, fallback.toolType) === null) {
          const backfill: ToolState = this.cloneState(fallback);
          backfill.trayIndex = primaryCount;
          primaryCount++;
          merged.push(backfill);
          missing.push(this.cloneState(backfill));
        }
      }
      merged.sort((a: ToolState, b: ToolState): number =>
        a.trayType - b.trayType || a.trayIndex - b.trayIndex);
      this.states = merged;
      this.syncToolStates();
      if (!this.isInitializationCurrent()) {
        return false;
      }
      if (loaded.length === 0) {
        await repository.saveToolStates(this.cloneStates(this.states));
      } else {
        for (const state of missing) {
          if (!this.isInitializationCurrent()) {
            return false;
          }
          await repository.saveToolState(this.cloneState(state));
        }
      }
      this.replaceCommittedStates(this.states);
      const toolbox: EditorToolboxState | null = await repository.getToolboxState(ownerId);
      if (!this.isInitializationCurrent()) {
        return false;
      }
      const visibleFallback: ToolState | null = this.findFirstVisibleType(ToolType.PEN) ??
        (this.visibleToolStates().length > 0 ? this.visibleToolStates()[0] :
          this.requireState(ToolType.PEN));
      const fallbackPen: ToolState = visibleFallback;
      const mostRecent: ToolState | null = toolbox === null ? null :
        this.findById(toolbox.mostRecentlySelectedToolId);
      const previous: ToolState | null = toolbox === null ? null :
        this.findById(toolbox.previouslySelectedToolId);
      // Hidden rows cannot be selected (x6f only exposes visible trays to the
      // toolbar), so a stale most-recent pointing at the Hidden tray falls back.
      if (mostRecent !== null && mostRecent.trayType !== TRAY_TYPE_HIDDEN) {
        this.activeToolId = mostRecent.toolId;
        this.previousToolId = previous !== null && previous.trayType !== TRAY_TYPE_HIDDEN ?
          previous.toolId : this.activeToolId;
      } else {
        this.activeToolId = fallbackPen.toolId;
        this.previousToolId = fallbackPen.toolId;
        await repository.saveToolboxState(this.toolboxSnapshot());
      }
      this.committedToolbox = this.cloneToolboxState(this.toolboxSnapshot());
      this.applyActiveState();
      // gr7 parity: seed original default wells once (idempotent), then load the
      // active tool's wells. Well failures are non-fatal for tool-state init.
      try {
        await repository.seedDefaultToolWells();
        await this.refreshWells(repository);
      } catch (wellError) {
        this.onPersistenceError(`Tool wells could not be loaded: ${JSON.stringify(wellError)}`);
      }
      if (settingsRepository !== null) {
        try {
          this.shapeDetectionEnabled = await settingsRepository.getShapeDetectionEnabled();
          this.autoDeselectEraser = await settingsRepository.getAutoDeselectEraser();
          this.palmDetectionEnabled = await settingsRepository.getPalmDetectionEnabled();
          this.straightLinesEnabled = await settingsRepository.getStraightLinesEnabled();
          this.laserShowTail = await settingsRepository.getLaserShowTail();
          if (!this.isInitializationCurrent()) {
            return false;
          }
          this.committedShapeDetectionEnabled = this.shapeDetectionEnabled;
        } catch (settingsError) {
          this.onPersistenceError(`Editor settings could not be loaded: ${JSON.stringify(settingsError)}`);
        }
      }
      this.toolStateLoading = false;
      return true;
    } catch (e) {
      this.states = defaults;
      this.syncToolStates();
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
      // 原版 dm2：tapePattern 仅随 TAPE(a6f.S=REVIEW) 工具的 CreateInkOp 下发。
      tapePattern: this.currentTool === ToolType.REVIEW ?
        this.activeTapePattern : undefined,
    };
  }

  async selectTool(tool: ToolType): Promise<boolean> {
    const requestedType: ToolType = this.canonicalType(tool);
    const target: ToolState | null = this.findFirstVisibleType(requestedType);
    if (target === null) {
      return false;
    }
    return this.selectToolInternal(target.toolId, tool);
  }

  // Duplicate-aware selection: each tool row carries its own tool_id, so the
  // toolbar selects the exact instance (the original's tool_id ≠ toolType model).
  // The row's own eraserIsPartial applies via applyActiveState — no mode write.
  async selectToolById(toolId: string): Promise<boolean> {
    const target: ToolState | null = this.findById(toolId);
    if (target === null || target.trayType === TRAY_TYPE_HIDDEN) {
      return false;
    }
    return this.selectToolInternal(toolId, target.toolType, false);
  }

  private async selectToolInternal(toolId: string, tool: ToolType,
    updateEraserMode: boolean = true): Promise<boolean> {
    if (this.toolStateLoading) {
      return false;
    }
    const requestedType: ToolType = this.canonicalType(tool);
    const target: ToolState | null = this.findById(toolId);
    if (target === null) {
      return false;
    }
    this.selectionVersion++;
    const version: number = this.selectionVersion;
    this.previousToolId = this.activeToolId;
    this.activeToolId = target.toolId;
    if (updateEraserMode && requestedType === ToolType.WHOLE_ERASER) {
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
    this.setEyedropperActive(false);
    this.refreshWells(this.repository).catch((wellError: Object): void => {
      this.onPersistenceError(`Tool wells could not be loaded: ${JSON.stringify(wellError)}`);
    });
    const repository: ToolRepository | null = this.repository;
    const snapshot: EditorToolboxState = this.toolboxSnapshot();
    if (repository === null) {
      this.committedToolbox = this.cloneToolboxState(snapshot);
      return true;
    }
    try {
      await this.enqueueSave(async (): Promise<void> => repository.saveToolboxState(snapshot));
      this.committedToolbox = this.cloneToolboxState(snapshot);
      // i8f.g parity: selection also rewrites the owning tray's lastUsedToolId.
      repository.setTrayLastUsedTool(target.trayType, this.ownerId, toolId)
        .catch((trayError: Object): void => {
          this.onPersistenceError(`Tray selection was not saved: ${JSON.stringify(trayError)}`);
        });
      return true;
    } catch (e) {
      if (this.selectionVersion === version) {
        this.restoreCommittedToolbox();
      }
      this.onPersistenceError(`Tool selection was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // selectedWellIndex is -1 when the pick did not come from a favorite well
  // (palette or recents tap), matching the original "no well selected" meaning.
  // 原版 lu7 状态机：i3 case12（显式开关）与 q5 case5（取样提交）都以
  // lu7.a(lu7, null, null, 6) 复位 enabled=false；本方法等价整态复位。
  setEyedropperActive(active: boolean, forSelection: boolean = false): void {
    this.eyedropperActive = active;
    this.eyedropperForSelection = active ? forSelection : false;
  }

  async setBrushColor(color: number, selectedWellIndex: number = -1): Promise<boolean> {
    const saved: boolean = await this.updateActiveState((state: ToolState): void => {
      state.brush.color = color;
      state.brush.selectedColorWellIndex = selectedWellIndex;
    });
    if (saved) {
      // ehb parity: every applied brush color lands in the global recents list.
      await this.recordRecentColor(color);
    }
    return saved;
  }

  async setBrushWidth(width: number, selectedWellIndex: number = -1): Promise<boolean> {
    const bounded: number = Math.max(2, Math.min(100, width));
    return this.updateActiveState((state: ToolState): void => {
      state.brush.widthSize = bounded;
      state.brush.selectedWidthWellIndex = selectedWellIndex;
    });
  }

  // 原版 nh9 → yh9(i3=1)：g5f.h 以点击图案序数复制工具态，ti9.q 应用并
  // 持久化（tool_state.tape_pattern）。激活行经 applyActiveState 即时生效。
  async setToolTapePattern(toolId: string, pattern: TapePattern): Promise<boolean> {
    const target: ToolState | null = this.findById(toolId);
    if (target === null || target.toolType !== ToolType.REVIEW ||
      pattern < TapePattern.STRIPES || pattern > TapePattern.CHECKERS) {
      return false;
    }
    return this.updateState(toolId, (state: ToolState): void => {
      state.tapePattern = pattern;
    });
  }

  async selectFavoriteColor(index: number): Promise<boolean> {
    if (index < 0 || index >= this.favoriteColors.length) {
      return false;
    }
    return this.setBrushColor(this.favoriteColors[index], index);
  }

  async selectWidthWell(index: number): Promise<boolean> {
    if (index < 0 || index >= this.widthWells.length) {
      return false;
    }
    return this.setBrushWidth(this.widthWells[index], index);
  }

  async setFavoriteColorWell(index: number, color: number): Promise<boolean> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null || index < 0 || !this.supportsColorControls()) {
      return false;
    }
    try {
      await repository.setFavoriteColor(this.activeToolType(), index, color);
      this.favoriteColors = await repository.getFavoriteColors(this.activeToolType());
      return true;
    } catch (e) {
      this.onPersistenceError(`Favorite color well was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async removeFavoriteColorWell(index: number): Promise<boolean> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null || index < 0 || !this.supportsColorControls()) {
      return false;
    }
    try {
      await repository.removeFavoriteColor(this.activeToolType(), index);
      this.favoriteColors = await repository.getFavoriteColors(this.activeToolType());
      return true;
    } catch (e) {
      this.onPersistenceError(`Favorite color well was not removed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // Original xg9 OnAddColorClick: appends a new favorite well seeded with the
  // current brush color (the original dispatch carries (toolType, index, mv6);
  // the write is an upsert at the next tray slot).
  async addFavoriteColorWell(): Promise<boolean> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null || !this.supportsColorControls()) {
      return false;
    }
    try {
      await repository.setFavoriteColor(this.activeToolType(), this.favoriteColors.length,
        this.brushColor);
      this.favoriteColors = await repository.getFavoriteColors(this.activeToolType());
      return true;
    } catch (e) {
      this.onPersistenceError(`Favorite color well was not added: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async setWidthWellAt(index: number, width: number): Promise<boolean> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null || index < 0 || !this.supportsBrushControls()) {
      return false;
    }
    try {
      await repository.setWidthWell(this.activeToolType(), index, width);
      this.widthWells = await repository.getWidthWells(this.activeToolType());
      return true;
    } catch (e) {
      this.onPersistenceError(`Width well was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async removeWidthWell(index: number): Promise<boolean> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null || index < 0 || !this.supportsBrushControls()) {
      return false;
    }
    try {
      await repository.removeWidthWell(this.activeToolType(), index);
      this.widthWells = await repository.getWidthWells(this.activeToolType());
      return true;
    } catch (e) {
      this.onPersistenceError(`Width well was not removed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // === Original toolbox customization (e47/cgf/x7f/wb4/i8f.a/d8f parity) ===

  visibleToolStates(): ToolState[] {
    const visible: ToolState[] = [];
    for (const state of this.toolStates) {
      if (state.trayType !== TRAY_TYPE_HIDDEN) {
        visible.push(state);
      }
    }
    visible.sort((a: ToolState, b: ToolState): number =>
      a.trayType - b.trayType || a.trayIndex - b.trayIndex);
    return visible;
  }

  hiddenToolStates(): ToolState[] {
    const hidden: ToolState[] = [];
    for (const state of this.toolStates) {
      if (state.trayType === TRAY_TYPE_HIDDEN) {
        hidden.push(state);
      }
    }
    hidden.sort((a: ToolState, b: ToolState): number => a.trayIndex - b.trayIndex);
    return hidden;
  }

  // o6f.java:142 — the settings surface flags "max-reached" at 12 visible tools.
  isPrimaryTrayFull(): boolean {
    return this.countTrayType(this.states, TRAY_TYPE_PRIMARY) >= MAX_PRIMARY_TOOLS;
  }

  // x7f case-0: the original refuses to delete the sole visible instance of a
  // tool type; only duplicates may be deleted.
  canDeleteTool(toolId: string): boolean {
    const tool: ToolState | null = this.findById(toolId);
    if (tool === null) {
      return false;
    }
    let count: number = 0;
    for (const state of this.states) {
      if (state.toolType === tool.toolType && state.trayType !== TRAY_TYPE_HIDDEN) {
        count++;
      }
    }
    return count > 1;
  }

  // x7f case-1: hide moves the tool to the END of the Hidden tray.
  async hideTool(toolId: string): Promise<boolean> {
    const tool: ToolState | null = this.findById(toolId);
    if (tool === null || tool.trayType === TRAY_TYPE_HIDDEN) {
      return false;
    }
    const insertIndex: number = this.countTrayType(this.states, TRAY_TYPE_HIDDEN);
    const sourceTray: number = tool.trayType;
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.moveToolToTray(toolId, TRAY_TYPE_HIDDEN, insertIndex);
      }
      this.moveStateLocally(toolId, TRAY_TYPE_HIDDEN, insertIndex);
      this.reindexTrayLocally(sourceTray);
      await this.fixActiveToolAfterStructuralOp();
    }, 'Tool could not be hidden');
  }

  // wb4: unhide appends to the Primary tray while it has < 12 tools, otherwise
  // to the Secondary tray tail.
  async showTool(toolId: string): Promise<boolean> {
    const tool: ToolState | null = this.findById(toolId);
    if (tool === null || tool.trayType !== TRAY_TYPE_HIDDEN) {
      return false;
    }
    const destTray: number = this.isPrimaryTrayFull() ? TRAY_TYPE_SECONDARY : TRAY_TYPE_PRIMARY;
    const insertIndex: number = this.countTrayType(this.states, destTray);
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.moveToolToTray(toolId, destTray, insertIndex);
      }
      this.moveStateLocally(toolId, destTray, insertIndex);
      this.reindexTrayLocally(TRAY_TYPE_HIDDEN);
    }, 'Tool could not be shown');
  }

  // i8f.a: move/reorder a tool into a tray at an index (clamped server-side).
  async moveToolToIndex(toolId: string, trayType: number, index: number): Promise<boolean> {
    const tool: ToolState | null = this.findById(toolId);
    if (tool === null) {
      return false;
    }
    const sourceTray: number = tool.trayType;
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.moveToolToTray(toolId, trayType, index);
      }
      this.moveStateLocally(toolId, trayType, index);
      if (sourceTray !== trayType) {
        this.reindexTrayLocally(sourceTray);
      }
      await this.fixActiveToolAfterStructuralOp();
    }, 'Tool could not be moved');
  }

  // settings_duplicate_tool parity (o94 case-13 → ti9/ng9): the copy keeps every
  // field, gets a fresh tool_id, and lands right after the source in its tray.
  async duplicateTool(toolId: string): Promise<boolean> {
    const source: ToolState | null = this.findById(toolId);
    if (source === null) {
      return false;
    }
    const copy: ToolState = this.cloneState(source);
    copy.toolId = this.uniqueToolId(source.toolId);
    copy.trayIndex = source.trayIndex + 1;
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.insertToolStateAt(copy);
      }
      for (const state of this.states) {
        if (state.trayType === copy.trayType && state.toolId !== copy.toolId &&
          state.trayIndex >= copy.trayIndex) {
          state.trayIndex += 1;
        }
      }
      this.states.splice(this.indexById(source.toolId) + 1, 0, copy);
      this.syncToolStates();
    }, 'Tool could not be duplicated');
  }

  // x7f case-0: refuse to delete the sole visible instance of a tool type.
  async deleteTool(toolId: string): Promise<boolean> {
    if (!this.canDeleteTool(toolId)) {
      return false;
    }
    const tool: ToolState | null = this.findById(toolId);
    if (tool === null) {
      return false;
    }
    const sourceTray: number = tool.trayType;
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.deleteToolState(toolId);
      }
      this.states.splice(this.indexById(toolId), 1);
      this.reindexTrayLocally(sourceTray);
      this.syncToolStates();
      await this.fixActiveToolAfterStructuralOp();
    }, 'Tool could not be deleted');
  }

  // d8f + yne(18) + gr7 parity: wipe tool/tray/selection rows, reseed the three
  // trays and the default tool set, and reselect the pen.
  async resetToolsToDefaults(): Promise<boolean> {
    if (this.toolStateLoading) {
      return false;
    }
    return this.runStructuralOp(async (): Promise<void> => {
      const repository: ToolRepository | null = this.repository;
      if (repository !== null) {
        await repository.deleteAllToolStates(this.ownerId);
        await repository.ensureTrays(this.ownerId);
        await repository.saveToolStates(this.cloneStates(this.createDefaultStates(this.ownerId)));
        const toolbox: EditorToolboxState = {
          ownerId: this.ownerId,
          mostRecentlySelectedToolId: 'pen',
          previouslySelectedToolId: 'pen',
        };
        await repository.saveToolboxState(toolbox);
        await repository.setTrayLastUsedTool(TRAY_TYPE_PRIMARY, this.ownerId, 'pen');
        this.committedToolbox = this.cloneToolboxState(toolbox);
      }
      this.states = this.createDefaultStates(this.ownerId);
      this.syncToolStates();
      this.activeToolId = 'pen';
      this.previousToolId = 'pen';
      this.applyActiveState();
      this.refreshWells(this.repository).catch((wellError: Object): void => {
        this.onPersistenceError(`Tool wells could not be loaded: ${JSON.stringify(wellError)}`);
      });
    }, 'Toolbox could not be reset');
  }

  private async runStructuralOp(operation: () => Promise<void>,
    message: string): Promise<boolean> {
    const snapshot: ToolState[] = this.cloneStates(this.states);
    try {
      await operation();
      this.syncToolStates();
      this.replaceCommittedStates(this.states);
      return true;
    } catch (e) {
      this.states = this.cloneStates(snapshot);
      this.syncToolStates();
      this.onPersistenceError(`${message}: ${JSON.stringify(e)}`);
      return false;
    }
  }

  private moveStateLocally(toolId: string, trayType: number, index: number): void {
    const from: number = this.indexById(toolId);
    if (from < 0) {
      return;
    }
    const state: ToolState = this.states[from];
    this.states.splice(from, 1);
    let clamped: number = index;
    const traySize: number = this.countTrayType(this.states, trayType);
    if (trayType === state.trayType && state.trayIndex < index) {
      clamped = index - 1;
    }
    clamped = Math.max(0, Math.min(clamped, traySize));
    state.trayType = trayType;
    state.trayIndex = clamped;
    this.states.splice(clamped + this.trayStartOffset(trayType), 0, state);
    this.reindexTrayLocally(trayType);
  }

  private reindexTrayLocally(trayType: number): void {
    let index: number = 0;
    for (const state of this.states) {
      if (state.trayType === trayType) {
        state.trayIndex = index;
        index++;
      }
    }
  }

  private trayStartOffset(trayType: number): number {
    let offset: number = 0;
    for (const state of this.states) {
      if (state.trayType === trayType) {
        return offset;
      }
      offset++;
    }
    return offset;
  }

  private countTrayType(states: ToolState[], trayType: number): number {
    let count: number = 0;
    for (const state of states) {
      if (state.trayType === trayType) {
        count++;
      }
    }
    return count;
  }

  private async fixActiveToolAfterStructuralOp(): Promise<void> {
    const active: ToolState | null = this.findById(this.activeToolId);
    if (active !== null && active.trayType !== TRAY_TYPE_HIDDEN) {
      return;
    }
    const visible: ToolState[] = this.visibleToolStates();
    if (visible.length === 0) {
      return;
    }
    this.previousToolId = this.activeToolId;
    this.activeToolId = visible[0].toolId;
    this.applyActiveState();
    const repository: ToolRepository | null = this.repository;
    if (repository !== null) {
      const snapshot: EditorToolboxState = this.toolboxSnapshot();
      await repository.saveToolboxState(snapshot);
      this.committedToolbox = this.cloneToolboxState(snapshot);
    }
  }

  private uniqueToolId(baseId: string): string {
    let candidate: string = `${baseId}-copy`;
    let counter: number = 2;
    while (this.findById(candidate) !== null) {
      candidate = `${baseId}-copy-${counter}`;
      counter++;
    }
    return candidate;
  }

  private findFirstVisibleType(type: ToolType): ToolState | null {
    for (const state of this.states) {
      if (state.toolType === type && state.trayType !== TRAY_TYPE_HIDDEN) {
        return state;
      }
    }
    return null;
  }

  // Mode-flag writes target the active instance when it has the type, else the
  // first row of the type (single-instance behavior for non-duplicated tools).
  private activeOrFirstType(type: ToolType): ToolState {
    const active: ToolState | null = this.findById(this.activeToolId);
    if (active !== null && active.toolType === type) {
      return active;
    }
    return this.requireState(type);
  }

  private syncToolStates(): void {
    this.toolStates = this.states.slice();
  }

  async setBrushStyle(style: BrushStyle): Promise<boolean> {
    return this.updateActiveState((state: ToolState): void => {
      state.brush.brushStyle = style;
    });
  }

  async setSelectionIsFreehand(isFreehand: boolean): Promise<boolean> {
    const state: ToolState = this.activeOrFirstType(ToolType.SELECTION);
    return this.updateState(state.toolId, (updated: ToolState): void => {
      updated.selectionIsFreehand = isFreehand;
    });
  }

  async setEraserIsPartial(isPartial: boolean): Promise<boolean> {
    const state: ToolState = this.activeOrFirstType(ToolType.WHOLE_ERASER);
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

  // 原版 gh9 OnLaserTailToggle → laser_preferences/show_tail 持久化。
  async setLaserShowTail(enabled: boolean): Promise<boolean> {
    this.laserShowTail = enabled;
    const repository: EditorSettingsRepository | null = this.settingsRepository;
    if (repository === null) {
      return true;
    }
    try {
      await this.enqueueSave(async (): Promise<void> => repository.saveLaserShowTail(enabled));
      return true;
    } catch (e) {
      this.laserShowTail = !enabled;
      this.onPersistenceError(`Laser tail setting was not saved: ${JSON.stringify(e)}`);
      return false;
    }
  }

  async flushToolState(): Promise<void> {
    await this.saveChain;
  }

  isEraserActive(): boolean {
    return this.currentTool === ToolType.PARTIAL_ERASER || this.currentTool === ToolType.WHOLE_ERASER;
  }

  // 原版 i8f.d parity：autoDeselectEraser 开启时，擦除手势结束后工具栏
  // 切回 previouslySelected 工具（对应 selectToolById(previousToolId)）。
  // 隐藏/失效/同工具时保持不动。
  async autoDeselectEraserAfterUse(): Promise<void> {
    if (!this.autoDeselectEraser || !this.isEraserActive()) {
      return;
    }
    const previous: ToolState | null = this.findById(this.previousToolId);
    if (previous === null || previous.trayType === TRAY_TYPE_HIDDEN ||
      previous.toolId === this.activeToolId) {
      return;
    }
    await this.selectToolById(previous.toolId);
  }

  isSelectionActive(): boolean {
    return this.currentTool === ToolType.SELECTION;
  }

  // 原版 a6f.R：激光笔为瞬态指示工具，不产生持久笔画。
  isLaserActive(): boolean {
    return this.currentTool === ToolType.LASER;
  }

  // Row-level selection check: with duplicated tools the toolbar highlights the
  // exact tool_id, not every row sharing the type.
  isActiveTool(toolId: string): boolean {
    return this.activeToolId === toolId;
  }

  // 原版 rz1:1075 REVIEW 有 5 色井 + [12,36,64] 三档宽度井——与书写工具
  // 同样暴露颜色/宽度控件。
  supportsBrushControls(): boolean {
    return this.currentTool === ToolType.PEN || this.currentTool === ToolType.PENCIL ||
      this.currentTool === ToolType.HIGHLIGHTER || this.currentTool === ToolType.REVIEW;
  }

  // 原版 rz1.p()：LASER 有 4 档颜色井但无宽度/样式井（15pt 固定单色宽）。
  supportsColorControls(): boolean {
    return this.supportsBrushControls() || this.currentTool === ToolType.LASER;
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
    if (!this.supportsBrushControls() && !this.isLaserActive()) {
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

  private async refreshWells(repository: ToolRepository | null): Promise<void> {
    if (repository === null) {
      this.favoriteColors = [];
      this.widthWells = [];
      this.recentColors = [];
      return;
    }
    this.recentColors = await repository.getRecentColors();
    if (!this.supportsColorControls()) {
      this.favoriteColors = [];
      this.widthWells = [];
      return;
    }
    const toolType: number = this.activeToolType();
    this.favoriteColors = await repository.getFavoriteColors(toolType);
    // 原版 j6g：LASER 宽度井仅 15pt 一档且无宽度 UI，不加载。
    this.widthWells = this.supportsBrushControls() ?
      await repository.getWidthWells(toolType) : [];
  }

  private async recordRecentColor(color: number): Promise<void> {
    const repository: ToolRepository | null = this.repository;
    if (repository === null) {
      return;
    }
    try {
      await repository.recordRecentColor(color);
      this.recentColors = await repository.getRecentColors();
    } catch (e) {
      this.onPersistenceError(`Recent color was not saved: ${JSON.stringify(e)}`);
    }
  }

  private activeToolType(): number {
    const state: ToolState | null = this.findById(this.activeToolId);
    return state === null ? ToolType.PEN : state.toolType;
  }

  private isInitializationCurrent(): boolean {
    return this.initializationGate === null || this.initializationGate();
  }

  private applyActiveState(): void {
    const state: ToolState | null = this.findById(this.activeToolId);
    if (state === null) {
      return;
    }
    this.brushColor = state.brush.color;
    this.brushWidth = state.brush.widthSize;
    this.brushStyle = state.brush.brushStyle;
    // Mode flags live per tool row: read them from the active instance so
    // duplicated selection/eraser tools keep their own modes.
    this.selectionIsFreehand = state.toolType === ToolType.SELECTION ?
      state.selectionIsFreehand : this.requireState(ToolType.SELECTION).selectionIsFreehand;
    this.eraserIsPartial = state.toolType === ToolType.WHOLE_ERASER ?
      state.eraserIsPartial : this.requireState(ToolType.WHOLE_ERASER).eraserIsPartial;
    const nextTool: ToolType = state.toolType === ToolType.WHOLE_ERASER && this.eraserIsPartial ?
      ToolType.PARTIAL_ERASER : state.toolType;
    if (nextTool !== this.currentTool) {
      this.toolChangedAt = Date.now();
    }
    this.currentTool = nextTool;
    if (state.toolType === ToolType.REVIEW) {
      this.activeTapePattern = state.tapePattern ?? TapePattern.STRIPES;
    }
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
    if (state.trayType < TRAY_TYPE_PRIMARY || state.trayType > TRAY_TYPE_HIDDEN) {
      state.trayType = TRAY_TYPE_PRIMARY;
    }
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
      // 原版 rz1.r()：LASER 默认在 Secondary 托盘 index 1；POINTER(0)/
      // RULER(4) 留空位——POINTER=多人 presence 光标（ac4.c0/b0 服务端协作
      // 域 fail-closed），RULER=s01.a0 无条件隐藏（ADR-0644/0642）。
      // ZOOM(2) 已由 Phase 747 移植（ADR-0690 更正 ZOOM_VIEW 默认开）。
      this.createState('laser', ownerId, ToolType.LASER, 1, -1754827, 15, BrushStyle.MONO,
        TRAY_TYPE_SECONDARY),
      // 原版 a6f.U ZOOM → rz1 副托盘 index 2：ZOOM_VIEW 旗标打包默认 true，
      // 1.0.3 默认可见。ZOOM 不产生笔画样式——借用 PEN 默认参数（黑/36/MONO）。
      this.createState('zoom', ownerId, ToolType.ZOOM, 2, -16777216, 36, BrushStyle.MONO,
        TRAY_TYPE_SECONDARY),
      // 原版 rz1:1075：REVIEW(a6f.S) 在 Secondary 托盘 index 3（POINTER=0 /
      // RULER=4 未移植、留空位），w31(-1706497, 36f, null, 0, 1, 0)：
      // 首色井、中档宽度井(1)、tapePattern=0(STRIPES)。
      this.createState('tape', ownerId, ToolType.REVIEW, 3, -1706497, 36, BrushStyle.MONO,
        TRAY_TYPE_SECONDARY, TapePattern.STRIPES, 0, 1),
    ];
  }

  private createState(toolId: string, ownerId: string, toolType: ToolType, trayIndex: number,
    color: number, width: number, style: BrushStyle, trayType: number = TRAY_TYPE_PRIMARY,
    tapePattern?: TapePattern, colorWellIndex: number = 0,
    widthWellIndex: number = 0): ToolState {
    return {
      toolId: toolId,
      trayOwnerId: ownerId,
      toolType: toolType,
      trayType: trayType,
      trayIndex: trayIndex,
      brush: {
        brushStyle: style,
        widthSize: width,
        color: color,
        selectedWidthWellIndex: widthWellIndex,
        selectedColorWellIndex: colorWellIndex,
      },
      tapePattern: tapePattern ?? null,
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
      trayType: state.trayType,
      trayIndex: state.trayIndex,
      brush: {
        brushStyle: state.brush.brushStyle,
        widthSize: state.brush.widthSize,
        color: state.brush.color,
        selectedWidthWellIndex: state.brush.selectedWidthWellIndex,
        selectedColorWellIndex: state.brush.selectedColorWellIndex,
      },
      tapePattern: state.tapePattern ?? null,
      selectionIsFreehand: state.selectionIsFreehand,
      eraserIsPartial: state.eraserIsPartial,
    };
  }
}

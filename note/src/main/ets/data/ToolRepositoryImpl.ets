import { relationalStore } from '@kit.ArkData';
import { EditorToolboxState, ToolState } from '../core/model/BrushTypes';
import { ToolRepository } from './RepositoryInterfaces';
import { AsyncMutex } from './AsyncMutex';
import { DatabaseManager } from './DatabaseManager';

export class ToolRepositoryImpl implements ToolRepository {
  private static writeMutex: AsyncMutex = new AsyncMutex();
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async getToolStates(ownerId: string): Promise<ToolState[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('tool_state');
    predicates.equalTo('tray_owner_id', ownerId);
    predicates.orderByAsc('tray_index');
    try {
      const resultSet = await store.query(predicates);
      const states: ToolState[] = [];
      try {
        while (resultSet.goToNextRow()) {
          states.push({
            toolId: resultSet.getString(resultSet.getColumnIndex('tool_id')),
            trayOwnerId: resultSet.getString(resultSet.getColumnIndex('tray_owner_id')),
            toolType: resultSet.getLong(resultSet.getColumnIndex('tool_type')),
            trayIndex: resultSet.getLong(resultSet.getColumnIndex('tray_index')),
            brush: {
              brushStyle: resultSet.getLong(resultSet.getColumnIndex('style')),
              widthSize: resultSet.getDouble(resultSet.getColumnIndex('width_size')),
              color: resultSet.getLong(resultSet.getColumnIndex('color')),
              selectedWidthWellIndex: resultSet.getLong(
                resultSet.getColumnIndex('selected_width_well_index')),
              selectedColorWellIndex: resultSet.getLong(
                resultSet.getColumnIndex('selected_color_well_index')),
            },
            selectionIsFreehand: resultSet.getLong(
              resultSet.getColumnIndex('selection_is_freehand')) !== 0,
            eraserIsPartial: resultSet.getLong(resultSet.getColumnIndex('eraser_is_partial')) !== 0,
          });
        }
      } finally {
        resultSet.close();
      }
      return states;
    } catch (e) {
      throw new Error(`getToolStates failed: ${JSON.stringify(e)}`);
    }
  }

  async saveToolState(state: ToolState): Promise<void> {
    await ToolRepositoryImpl.writeMutex.runExclusive(async (): Promise<void> => {
      try {
        await this.db.getStore().insert('tool_state', this.toBucket(state),
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      } catch (e) {
        throw new Error(`saveToolState failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async saveToolStates(states: ToolState[]): Promise<void> {
    await ToolRepositoryImpl.writeMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        for (let index: number = 0; index < states.length; index++) {
          const state: ToolState = this.cloneState(states[index]);
          state.trayIndex = index;
          await store.insert('tool_state', this.toBucket(state),
            relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`saveToolStates failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async deleteToolState(toolId: string): Promise<void> {
    await ToolRepositoryImpl.writeMutex.runExclusive(async (): Promise<void> => {
      try {
        const predicates = new relationalStore.RdbPredicates('tool_state');
        predicates.equalTo('tool_id', toolId);
        await this.db.getStore().delete(predicates);
      } catch (e) {
        throw new Error(`deleteToolState failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getToolboxState(ownerId: string): Promise<EditorToolboxState | null> {
    const predicates = new relationalStore.RdbPredicates('editor_toolbox_state');
    predicates.equalTo('owner_id', ownerId);
    try {
      const resultSet = await this.db.getStore().query(predicates);
      try {
        if (!resultSet.goToFirstRow()) {
          return null;
        }
        return {
          ownerId: resultSet.getString(resultSet.getColumnIndex('owner_id')),
          mostRecentlySelectedToolId: resultSet.getString(
            resultSet.getColumnIndex('most_recent_tool_id')),
          previouslySelectedToolId: resultSet.getString(resultSet.getColumnIndex('previous_tool_id')),
        };
      } finally {
        resultSet.close();
      }
    } catch (e) {
      throw new Error(`getToolboxState failed: ${JSON.stringify(e)}`);
    }
  }

  async saveToolboxState(state: EditorToolboxState): Promise<void> {
    await ToolRepositoryImpl.writeMutex.runExclusive(async (): Promise<void> => {
      const bucket: relationalStore.ValuesBucket = {
        'owner_id': state.ownerId,
        'most_recent_tool_id': state.mostRecentlySelectedToolId,
        'previous_tool_id': state.previouslySelectedToolId,
      };
      try {
        await this.db.getStore().insert('editor_toolbox_state', bucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      } catch (e) {
        throw new Error(`saveToolboxState failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private toBucket(state: ToolState): relationalStore.ValuesBucket {
    return {
      'tool_id': state.toolId,
      'tray_owner_id': state.trayOwnerId,
      'tool_type': state.toolType,
      'tray_index': state.trayIndex,
      'color': state.brush.color,
      'width_size': state.brush.widthSize,
      'style': state.brush.brushStyle,
      'selected_color_well_index': state.brush.selectedColorWellIndex,
      'selected_width_well_index': state.brush.selectedWidthWellIndex,
      'selection_is_freehand': state.selectionIsFreehand ? 1 : 0,
      'eraser_is_partial': state.eraserIsPartial ? 1 : 0,
    };
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

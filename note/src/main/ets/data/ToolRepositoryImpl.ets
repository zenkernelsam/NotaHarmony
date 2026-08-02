// T-017 ToolRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { ToolState } from '../core/model/BrushTypes';
import { ToolRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';

export class ToolRepositoryImpl implements ToolRepository {
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
            selectedWidthWellIndex: resultSet.getLong(resultSet.getColumnIndex('selected_width_well_index')),
            selectedColorWellIndex: resultSet.getLong(resultSet.getColumnIndex('selected_color_well_index')),
          },
          selectionIsFreehand: resultSet.getLong(resultSet.getColumnIndex('selection_is_freehand')) !== 0,
          eraserIsPartial: resultSet.getLong(resultSet.getColumnIndex('eraser_is_partial')) !== 0,
        });
      }
      resultSet.close();
      return states;
    } catch (e) {
      console.error(`getToolStates failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  async saveToolState(state: ToolState): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
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
    try {
      await store.insert('tool_state', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      console.error(`saveToolState failed: ${JSON.stringify(e)}`);
    }
  }
}

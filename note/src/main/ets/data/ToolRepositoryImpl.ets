import { relationalStore } from '@kit.ArkData';
import { EditorToolboxState, ToolState, ToolType } from '../core/model/BrushTypes';
import { ToolRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { databaseWriteMutex } from './DatabaseWriteMutex';

interface WellSeed {
  toolType: number;
  values: number[];
}

interface WellRow {
  id: number;
  trayIndex: number;
  value: number;
}

// Original default FavoriteColorWellEntity rows, rz1.p() mapped onto Harmony ToolType.
// LASER is intentionally absent: Harmony has no laser tool.
const DEFAULT_FAVORITE_WELLS: WellSeed[] = [
  { toolType: ToolType.PEN, values: [-16777216, -15260469, -2011583] },
  { toolType: ToolType.PENCIL, values: [-16777216, -15260469, -2011583] },
  { toolType: ToolType.HIGHLIGHTER, values: [-172, -4391597, -1428530] },
  { toolType: ToolType.REVIEW, values: [-1706497, -672330, -6303021, -11872, -2238485] },
];

// Original default WidthSizeWellEntity rows, rz1.s() mapped onto Harmony ToolType.
// ERASER maps to WHOLE_ERASER; LASER is intentionally absent.
const DEFAULT_WIDTH_WELLS: WellSeed[] = [
  { toolType: ToolType.PEN, values: [1.0, 2.0, 4.0] },
  { toolType: ToolType.PENCIL, values: [1.5, 3.0, 5.0] },
  { toolType: ToolType.HIGHLIGHTER, values: [20.0, 15.0, 10.0] },
  { toolType: ToolType.WHOLE_ERASER, values: [4.0, 7.5, 15.0] },
  { toolType: ToolType.REVIEW, values: [12.0, 36.0, 64.0] },
];

// ehb.java: recents keep at most 7 rows; a new color trims the oldest down to 6 first.
const RECENT_COLOR_LIMIT: number = 7;

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
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      try {
        await this.db.getStore().insert('tool_state', this.toBucket(state),
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      } catch (e) {
        throw new Error(`saveToolState failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async saveToolStates(states: ToolState[]): Promise<void> {
    if (states.length === 0) {
      return;
    }
    const ownerId: string = states[0].trayOwnerId;
    for (const state of states) {
      if (state.trayOwnerId !== ownerId) {
        throw new Error('saveToolStates requires one toolbox owner per batch');
      }
    }
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const stale = new relationalStore.RdbPredicates('tool_state');
        stale.equalTo('tray_owner_id', ownerId);
        await store.delete(stale);
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
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
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
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
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

  // Mirrors the original i8f read: rows ordered by tray_index, with the self-heal that
  // rewrites dense 0..n-1 indices when the last row's trayIndex exceeds the row count.
  async getFavoriteColors(toolType: number): Promise<number[]> {
    const rows: WellRow[] = await this.queryWellRows('favorite_color_well', 'color', toolType);
    await this.healWellRows('favorite_color_well', rows);
    return rows.map((row: WellRow): number => row.value);
  }

  // Mirrors i8f: upsert at (toolType, trayIndex) preserving id, else insert a new row.
  async setFavoriteColor(toolType: number, trayIndex: number, color: number): Promise<void> {
    await this.upsertWell('favorite_color_well', 'color', toolType, trayIndex, color);
  }

  // Mirrors tb4.java: shift tray_index down past the removed slot, then delete the row.
  async removeFavoriteColor(toolType: number, trayIndex: number): Promise<void> {
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        await store.executeSql(
          'UPDATE favorite_color_well SET tray_index = tray_index - 1 WHERE tray_index > ? AND tool_type = ?',
          [trayIndex, toolType]);
        const predicates = new relationalStore.RdbPredicates('favorite_color_well');
        predicates.equalTo('tool_type', toolType);
        predicates.equalTo('tray_index', trayIndex);
        await store.delete(predicates);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`removeFavoriteColor failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getWidthWells(toolType: number): Promise<number[]> {
    const rows: WellRow[] = await this.queryWellRows('width_size_well', 'width', toolType);
    await this.healWellRows('width_size_well', rows);
    return rows.map((row: WellRow): number => row.value);
  }

  async setWidthWell(toolType: number, trayIndex: number, width: number): Promise<void> {
    await this.upsertWell('width_size_well', 'width', toolType, trayIndex, width);
  }

  // The original has no trayIndex shift-down for WidthSizeWellEntity; deleting the row is
  // enough because the read path repairs non-dense indices.
  async removeWidthWell(toolType: number, trayIndex: number): Promise<void> {
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      try {
        const predicates = new relationalStore.RdbPredicates('width_size_well');
        predicates.equalTo('tool_type', toolType);
        predicates.equalTo('tray_index', trayIndex);
        await this.db.getStore().delete(predicates);
      } catch (e) {
        throw new Error(`removeWidthWell failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Mirrors m2a.java:139 — global recents ordered by timestamp DESC.
  async getRecentColors(): Promise<number[]> {
    try {
      const resultSet: relationalStore.ResultSet = await this.db.getStore().querySql(
        'SELECT color FROM recent_color_well ORDER BY timestamp DESC', []);
      const colors: number[] = [];
      try {
        while (resultSet.goToNextRow()) {
          colors.push(resultSet.getLong(0));
        }
      } finally {
        resultSet.close();
      }
      return colors;
    } catch (e) {
      throw new Error(`getRecentColors failed: ${JSON.stringify(e)}`);
    }
  }

  // Mirrors ehb.java: an existing color only refreshes its timestamp; a new color first
  // trims the oldest rows so the list never exceeds RECENT_COLOR_LIMIT entries.
  async recordRecentColor(color: number): Promise<void> {
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const existing: relationalStore.ResultSet = await store.querySql(
          'SELECT id FROM recent_color_well WHERE color = ?', [color]);
        let existingId: number = -1;
        try {
          if (existing.goToNextRow()) {
            existingId = existing.getLong(0);
          }
        } finally {
          existing.close();
        }
        const now: number = Date.now();
        if (existingId >= 0) {
          const bucket: relationalStore.ValuesBucket = {
            'id': existingId,
            'color': color,
            'timestamp': now,
          };
          await store.insert('recent_color_well', bucket,
            relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        } else {
          const count: number = await this.countRows(store, 'recent_color_well');
          if (count >= RECENT_COLOR_LIMIT) {
            await store.executeSql(
              'DELETE FROM recent_color_well WHERE id IN (SELECT id FROM recent_color_well ORDER BY timestamp ASC LIMIT ?)',
              [count - RECENT_COLOR_LIMIT + 1]);
          }
          const bucket: relationalStore.ValuesBucket = {
            'color': color,
            'timestamp': now,
          };
          await store.insert('recent_color_well', bucket);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`recordRecentColor failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Mirrors gr7.java first-run seeding: original defaults are inserted once; the
  // empty-table guard keeps the call idempotent for existing installs.
  async seedDefaultToolWells(): Promise<void> {
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        if (await this.countRows(store, 'favorite_color_well') === 0) {
          for (const seed of DEFAULT_FAVORITE_WELLS) {
            for (let index: number = 0; index < seed.values.length; index++) {
              const bucket: relationalStore.ValuesBucket = {
                'tool_type': seed.toolType,
                'color': seed.values[index],
                'tray_index': index,
              };
              await store.insert('favorite_color_well', bucket);
            }
          }
        }
        if (await this.countRows(store, 'width_size_well') === 0) {
          for (const seed of DEFAULT_WIDTH_WELLS) {
            for (let index: number = 0; index < seed.values.length; index++) {
              const bucket: relationalStore.ValuesBucket = {
                'tool_type': seed.toolType,
                'width': seed.values[index],
                'tray_index': index,
              };
              await store.insert('width_size_well', bucket);
            }
          }
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`seedDefaultToolWells failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async queryWellRows(table: string, valueColumn: string,
    toolType: number): Promise<WellRow[]> {
    const predicates = new relationalStore.RdbPredicates(table);
    predicates.equalTo('tool_type', toolType);
    predicates.orderByAsc('tray_index');
    try {
      const resultSet: relationalStore.ResultSet = await this.db.getStore().query(predicates);
      const rows: WellRow[] = [];
      try {
        while (resultSet.goToNextRow()) {
          rows.push({
            id: resultSet.getLong(resultSet.getColumnIndex('id')),
            trayIndex: resultSet.getLong(resultSet.getColumnIndex('tray_index')),
            value: valueColumn === 'width' ?
              resultSet.getDouble(resultSet.getColumnIndex(valueColumn)) :
              resultSet.getLong(resultSet.getColumnIndex(valueColumn)),
          });
        }
      } finally {
        resultSet.close();
      }
      return rows;
    } catch (e) {
      throw new Error(`queryWellRows failed: ${JSON.stringify(e)}`);
    }
  }

  private async healWellRows(table: string, rows: WellRow[]): Promise<void> {
    if (rows.length === 0 || rows[rows.length - 1].trayIndex < rows.length) {
      return;
    }
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        for (let index: number = 0; index < rows.length; index++) {
          await store.executeSql(`UPDATE ${table} SET tray_index = ? WHERE id = ?`,
            [index, rows[index].id]);
          rows[index].trayIndex = index;
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`healWellRows failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async upsertWell(table: string, valueColumn: string, toolType: number,
    trayIndex: number, value: number): Promise<void> {
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      try {
        const predicates = new relationalStore.RdbPredicates(table);
        predicates.equalTo('tool_type', toolType);
        predicates.equalTo('tray_index', trayIndex);
        const resultSet: relationalStore.ResultSet = await store.query(predicates);
        let existingId: number = -1;
        try {
          if (resultSet.goToNextRow()) {
            existingId = resultSet.getLong(resultSet.getColumnIndex('id'));
          }
        } finally {
          resultSet.close();
        }
        const bucket: relationalStore.ValuesBucket = {};
        if (existingId >= 0) {
          bucket['id'] = existingId;
        }
        bucket['tool_type'] = toolType;
        bucket[valueColumn] = value;
        bucket['tray_index'] = trayIndex;
        await store.insert(table, bucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      } catch (e) {
        throw new Error(`upsertWell failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async countRows(store: relationalStore.RdbStore, table: string): Promise<number> {
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT COUNT(*) FROM ${table}`, []);
    try {
      return resultSet.goToNextRow() ? resultSet.getLong(0) : 0;
    } finally {
      resultSet.close();
    }
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

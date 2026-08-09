import { relationalStore } from '@kit.ArkData';
import { HistoryEffect, HistoryMetadata, Op, OpSyncMetadata, SequencedOp } from '../core/model/OpTypes';
import { OpStore } from '../core/op/OpStore';
import { DatabaseManager } from './DatabaseManager';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import {
  PersistentHistoryAction, PersistentHistoryState, reducePersistentHistoryTail, trimPersistentHistoryState,
} from './PersistentHistory';
import {
  encodeOperationId, nextOperationTimestamp, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';

export interface AllocatedOperationIdentity extends OperationIdentity {
  opId: string;
  clientTime: number;
}

export interface PersistentHistoryReplay {
  state: PersistentHistoryState;
  checkpointUsed: boolean;
  tailOperationCount: number;
}

export interface PersistentHistoryCheckpointResult {
  throughSequence: number;
  retainedActions: number;
  removedDeleteCheckpoints: number;
}

export interface PersistentHistoryResetResult {
  throughSequence: number;
  removedDeleteCheckpoints: number;
}

interface StoredHistoryCheckpoint {
  throughSequence: number;
  state: PersistentHistoryState;
}

const UNDO_STACK_KIND: number = 0;
const REDO_STACK_KIND: number = 1;

export class OpStoreImpl implements OpStore {
  private store: relationalStore.RdbStore;

  constructor(db: DatabaseManager) {
    this.store = db.getStore();
  }

  async appendOp(op: Op): Promise<void> {
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      await this.store.beginTransaction();
      try {
        await ensureNoteSyncMetadata(this.store, op.noteId);
        const metadata: OpSyncMetadata = await readNoteSyncMetadata(this.store, op.noteId);
        await appendOperation(this.store, op);
        if (op.opTimestamp !== undefined && op.opTimestamp > metadata.maxOpTimestamp) {
          const predicates = new relationalStore.RdbPredicates('note_sync_metadata');
          predicates.equalTo('note_id', op.noteId);
          predicates.equalTo('max_op_timestamp', metadata.maxOpTimestamp);
          const updated: number = await this.store.update({
            'max_op_timestamp': op.opTimestamp,
            'updated_at': Math.max(metadata.updatedAt, op.clientTime),
          }, predicates);
          if (updated !== 1) {
            throw new Error('external append did not advance the operation clock');
          }
        }
        await this.store.commit();
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`append operation failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getOps(noteId: string): Promise<Op[]> {
    return this.queryOps(
      `SELECT op_id, note_id, op_type, payload, client_time, op_timestamp, editor_site_id,
        upload_immediately,
        action_id, history_effect, coalesce_track, action_time FROM operation_log
       WHERE note_id = ? ORDER BY client_time, sequence`, [noteId]);
  }

  async getOpsSince(noteId: string, sinceTime: number): Promise<Op[]> {
    return this.queryOps(
      `SELECT op_id, note_id, op_type, payload, client_time, op_timestamp, editor_site_id,
        upload_immediately,
        action_id, history_effect, coalesce_track, action_time FROM operation_log
       WHERE note_id = ? AND client_time > ? ORDER BY client_time, sequence`, [noteId, sinceTime]);
  }

  async deleteOps(noteId: string): Promise<void> {
    if (noteId.length === 0) {
      throw new Error('delete operations requires a note ID');
    }
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      await this.store.beginTransaction();
      try {
        const predicates = new relationalStore.RdbPredicates('operation_log');
        predicates.equalTo('note_id', noteId);
        await this.store.delete(predicates);
        for (const table of ['history_checkpoint', 'page_delete_checkpoint']) {
          const checkpointPredicates = new relationalStore.RdbPredicates(table);
          checkpointPredicates.equalTo('note_id', noteId);
          await this.store.delete(checkpointPredicates);
        }
        const syncPredicates = new relationalStore.RdbPredicates('note_sync_metadata');
        syncPredicates.equalTo('note_id', noteId);
        await this.store.update({
          'synced_op_count': 0,
          'uploaded_through_sequence': 0,
          'acked_through_sequence': 0,
        }, syncPredicates);
        await this.store.commit();
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`delete operations failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getOpCount(noteId: string): Promise<number> {
    const resultSet = await this.store.querySql(
      'SELECT COUNT(*) AS op_count FROM operation_log WHERE note_id = ?', [noteId]);
    try {
      return resultSet.goToFirstRow() ? resultSet.getLong(resultSet.getColumnIndex('op_count')) : 0;
    } finally {
      resultSet.close();
    }
  }

  async getPendingOps(noteId: string, limit: number): Promise<SequencedOp[]> {
    if (noteId.length === 0 || !Number.isSafeInteger(limit) || limit < 1 || limit > 1024) {
      throw new Error('pending operation query is invalid');
    }
    const metadata: OpSyncMetadata = await this.getSyncMetadata(noteId);
    const rows = await this.store.querySql(
      `SELECT sequence, op_id, note_id, op_type, payload, client_time, op_timestamp, editor_site_id,
        upload_immediately, action_id, history_effect, coalesce_track, action_time FROM operation_log
       WHERE note_id = ? AND sequence > ? ORDER BY sequence LIMIT ?`,
      [noteId, metadata.ackedThroughSequence, limit]);
    const result: SequencedOp[] = [];
    try {
      while (rows.goToNextRow()) {
        result.push({
          sequence: rows.getLong(rows.getColumnIndex('sequence')),
          op: readOperationRow(rows),
        });
      }
    } finally {
      rows.close();
    }
    return result;
  }

  async getSyncMetadata(noteId: string): Promise<OpSyncMetadata> {
    if (noteId.length === 0) {
      throw new Error('sync metadata requires a note ID');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<OpSyncMetadata> => {
      await ensureNoteSyncMetadata(this.store, noteId);
      return readNoteSyncMetadata(this.store, noteId);
    });
  }

  async markOpsUploaded(noteId: string, throughSequence: number): Promise<void> {
    await this.advanceSyncWatermark(noteId, throughSequence, null);
  }

  async acknowledgeUploadedOps(noteId: string, throughSequence: number,
    maxServerTime: number): Promise<void> {
    if (!Number.isSafeInteger(maxServerTime) || maxServerTime < 0) {
      throw new Error('server time is invalid');
    }
    await this.advanceSyncWatermark(noteId, throughSequence, maxServerTime);
  }

  private async advanceSyncWatermark(noteId: string, throughSequence: number,
    acknowledgedServerTime: number | null): Promise<void> {
    if (noteId.length === 0 || !Number.isSafeInteger(throughSequence) || throughSequence <= 0) {
      throw new Error('sync watermark is invalid');
    }
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      await this.store.beginTransaction();
      try {
        await ensureNoteSyncMetadata(this.store, noteId);
        const metadata: OpSyncMetadata = await readNoteSyncMetadata(this.store, noteId);
        const owner = await this.store.querySql(
          'SELECT note_id FROM operation_log WHERE sequence = ?', [throughSequence]);
        try {
          if (!owner.goToFirstRow() || owner.getString(owner.getColumnIndex('note_id')) !== noteId) {
            throw new Error('sync watermark does not identify an operation from this note');
          }
        } finally {
          owner.close();
        }
        const bucket: relationalStore.ValuesBucket = {};
        if (acknowledgedServerTime === null) {
          if (throughSequence < metadata.uploadedThroughSequence) {
            throw new Error('uploaded watermark cannot move backwards');
          }
          bucket['uploaded_through_sequence'] = throughSequence;
        } else {
          if (throughSequence < metadata.ackedThroughSequence ||
            throughSequence > metadata.uploadedThroughSequence) {
            throw new Error('acknowledged watermark is outside the uploaded prefix');
          }
          bucket['acked_through_sequence'] = throughSequence;
          bucket['max_server_time'] = metadata.maxServerTime === null
            ? acknowledgedServerTime : Math.max(metadata.maxServerTime, acknowledgedServerTime);
          const countSet = await this.store.querySql(
            'SELECT COUNT(*) AS op_count FROM operation_log WHERE note_id = ? AND sequence <= ?',
            [noteId, throughSequence]);
          try {
            if (!countSet.goToFirstRow()) {
              throw new Error('acknowledged operation count query failed');
            }
            bucket['synced_op_count'] = countSet.getLong(countSet.getColumnIndex('op_count'));
          } finally {
            countSet.close();
          }
        }
        const predicates = new relationalStore.RdbPredicates('note_sync_metadata');
        predicates.equalTo('note_id', noteId);
        const updated: number = await this.store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error('sync watermark update did not affect exactly one note');
        }
        await this.store.commit();
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`advance sync watermark failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getPersistentHistory(noteId: string): Promise<PersistentHistoryReplay> {
    if (noteId.length === 0) {
      throw new Error('persistent history requires a note ID');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<PersistentHistoryReplay> =>
      this.getPersistentHistoryLocked(noteId));
  }

  private async getPersistentHistoryLocked(noteId: string): Promise<PersistentHistoryReplay> {
    const checkpoint: StoredHistoryCheckpoint | null = await this.readHistoryCheckpoint(noteId);
    if (checkpoint !== null) {
      await this.validateCheckpointSequence(noteId, checkpoint.throughSequence);
    }
    const tail: Op[] = checkpoint === null
      ? await this.getOps(noteId) : await this.queryOps(
        `SELECT op_id, note_id, op_type, payload, client_time, op_timestamp, editor_site_id,
          upload_immediately,
          action_id, history_effect, coalesce_track, action_time FROM operation_log
         WHERE note_id = ? AND sequence > ? ORDER BY client_time, sequence`,
        [noteId, checkpoint.throughSequence]);
    const initial: PersistentHistoryState = checkpoint === null
      ? { undo: [], redo: [], legacyOperationCount: 0 } : checkpoint.state;
    return {
      state: reducePersistentHistoryTail(initial, tail),
      checkpointUsed: checkpoint !== null,
      tailOperationCount: tail.length,
    };
  }

  async checkpointPersistentHistory(noteId: string,
    maxActions: number): Promise<PersistentHistoryCheckpointResult> {
    if (noteId.length === 0) {
      throw new Error('history checkpoint requires a note ID');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<PersistentHistoryCheckpointResult> =>
      this.checkpointPersistentHistoryLocked(noteId, maxActions));
  }

  private async checkpointPersistentHistoryLocked(noteId: string,
    maxActions: number): Promise<PersistentHistoryCheckpointResult> {
    await this.store.beginTransaction();
    try {
      const checkpoint: StoredHistoryCheckpoint | null = await this.readHistoryCheckpoint(noteId);
      if (checkpoint !== null) {
        await this.validateCheckpointSequence(noteId, checkpoint.throughSequence);
      }
      const tail: Op[] = checkpoint === null
        ? await this.getOps(noteId) : await this.queryOps(
          `SELECT op_id, note_id, op_type, payload, client_time, op_timestamp, editor_site_id,
            upload_immediately,
            action_id, history_effect, coalesce_track, action_time FROM operation_log
           WHERE note_id = ? AND sequence > ? ORDER BY client_time, sequence`,
          [noteId, checkpoint.throughSequence]);
      const initial: PersistentHistoryState = checkpoint === null
        ? { undo: [], redo: [], legacyOperationCount: 0 } : checkpoint.state;
      const reduced: PersistentHistoryState = reducePersistentHistoryTail(initial, tail);
      const retained: PersistentHistoryState = trimPersistentHistoryState(reduced, maxActions);
      const throughSequence: number = await this.getLatestSequence(noteId);
      if (throughSequence <= 0) {
        throw new Error('cannot checkpoint an empty operation log');
      }
      await this.replaceHistoryCheckpoint(noteId, throughSequence, retained);
      const removed: number = await this.removeUnreferencedDeleteCheckpoints(noteId, retained);
      await this.store.commit();
      return {
        throughSequence: throughSequence,
        retainedActions: retained.undo.length + retained.redo.length,
        removedDeleteCheckpoints: removed,
      };
    } catch (e) {
      await this.store.rollBack();
      throw new Error(`checkpoint persistent history failed: ${JSON.stringify(e)}`);
    }
  }

  async resetPersistentHistory(noteId: string): Promise<PersistentHistoryResetResult> {
    if (noteId.length === 0) {
      throw new Error('history reset requires a note ID');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<PersistentHistoryResetResult> =>
      this.resetPersistentHistoryLocked(noteId));
  }

  private async resetPersistentHistoryLocked(noteId: string): Promise<PersistentHistoryResetResult> {
    await this.store.beginTransaction();
    try {
      const throughSequence: number = await this.getLatestSequence(noteId);
      const empty: PersistentHistoryState = { undo: [], redo: [], legacyOperationCount: 0 };
      if (throughSequence > 0) {
        await this.replaceHistoryCheckpoint(noteId, throughSequence, empty);
      } else {
        const predicates = new relationalStore.RdbPredicates('history_checkpoint');
        predicates.equalTo('note_id', noteId);
        await this.store.delete(predicates);
      }
      const removed: number = await this.removeUnreferencedDeleteCheckpoints(noteId, empty);
      await this.store.commit();
      return { throughSequence: throughSequence, removedDeleteCheckpoints: removed };
    } catch (e) {
      await this.store.rollBack();
      throw new Error(`reset persistent history failed: ${JSON.stringify(e)}`);
    }
  }

  private async queryOps(sql: string, args: relationalStore.ValueType[]): Promise<Op[]> {
    const resultSet = await this.store.querySql(sql, args);
    const result: Op[] = [];
    try {
      while (resultSet.goToNextRow()) {
        result.push(readOperationRow(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  private async readHistoryCheckpoint(noteId: string): Promise<StoredHistoryCheckpoint | null> {
    const header = await this.store.querySql(
      `SELECT through_sequence, legacy_operation_count FROM history_checkpoint WHERE note_id = ?`, [noteId]);
    let throughSequence: number = 0;
    let legacyOperationCount: number = 0;
    try {
      if (!header.goToFirstRow()) {
        return null;
      }
      throughSequence = header.getLong(header.getColumnIndex('through_sequence'));
      legacyOperationCount = header.getLong(header.getColumnIndex('legacy_operation_count'));
      if (!Number.isSafeInteger(throughSequence) || throughSequence <= 0 ||
        !Number.isSafeInteger(legacyOperationCount) || legacyOperationCount < 0) {
        throw new Error('history checkpoint header is invalid');
      }
    } finally {
      header.close();
    }
    const state: PersistentHistoryState = {
      undo: [], redo: [], legacyOperationCount: legacyOperationCount,
    };
    const rows = await this.store.querySql(
      `SELECT action.stack_kind, action.stack_index, action.action_id, action.coalesce_track,
        action.action_time, operation.operation_index, operation.op_id, operation.op_type,
        operation.payload, operation.client_time
       FROM history_checkpoint_action action
       LEFT JOIN history_checkpoint_operation operation
         ON operation.note_id = action.note_id AND operation.stack_kind = action.stack_kind
           AND operation.stack_index = action.stack_index
       WHERE action.note_id = ?
       ORDER BY action.stack_kind, action.stack_index, operation.operation_index`, [noteId]);
    const actionIds: Set<string> = new Set<string>();
    const opIds: Set<string> = new Set<string>();
    const expectedStackIndex: number[] = [0, 0];
    let active: PersistentHistoryAction | null = null;
    let activeKind: number = -1;
    let activeIndex: number = -1;
    let expectedOperationIndex: number = 0;
    try {
      while (rows.goToNextRow()) {
        const kind: number = rows.getLong(rows.getColumnIndex('stack_kind'));
        const stackIndex: number = rows.getLong(rows.getColumnIndex('stack_index'));
        if ((kind !== UNDO_STACK_KIND && kind !== REDO_STACK_KIND) ||
          !Number.isSafeInteger(stackIndex) || stackIndex < 0) {
          throw new Error('history checkpoint stack position is invalid');
        }
        if (active === null || activeKind !== kind || activeIndex !== stackIndex) {
          if (stackIndex !== expectedStackIndex[kind]) {
            throw new Error('history checkpoint stack indexes are discontinuous');
          }
          expectedStackIndex[kind]++;
          const actionId: string = rows.getString(rows.getColumnIndex('action_id'));
          const track: number = rows.getLong(rows.getColumnIndex('coalesce_track'));
          const actionTime: number = rows.getLong(rows.getColumnIndex('action_time'));
          const history: HistoryMetadata = {
            actionId: actionId, effect: HistoryEffect.PUSH, coalesceTrack: track, actionTime: actionTime,
          };
          validateHistoryMetadata(history);
          if (actionIds.has(actionId)) {
            throw new Error('history checkpoint contains duplicate action identities');
          }
          actionIds.add(actionId);
          active = { actionId: actionId, coalesceTrack: track, actionTime: actionTime, operations: [] };
          (kind === UNDO_STACK_KIND ? state.undo : state.redo).push(active);
          activeKind = kind;
          activeIndex = stackIndex;
          expectedOperationIndex = 0;
        }
        const operationColumn: number = rows.getColumnIndex('operation_index');
        if (rows.isColumnNull(operationColumn) || rows.getLong(operationColumn) !== expectedOperationIndex) {
          throw new Error('history checkpoint operation indexes are discontinuous');
        }
        expectedOperationIndex++;
        const opId: string = rows.getString(rows.getColumnIndex('op_id'));
        const clientTime: number = rows.getLong(rows.getColumnIndex('client_time'));
        if (opId.length === 0 || !Number.isSafeInteger(clientTime) || clientTime < 0 || opIds.has(opId)) {
          throw new Error('history checkpoint operation identity is invalid');
        }
        opIds.add(opId);
        if (active === null) {
          throw new Error('history checkpoint operation has no action');
        }
        active.operations.push({
          opId: opId,
          noteId: noteId,
          opType: rows.getLong(rows.getColumnIndex('op_type')),
          payload: rows.getBlob(rows.getColumnIndex('payload')),
          clientTime: clientTime,
          history: {
            actionId: active.actionId, effect: HistoryEffect.PUSH,
            coalesceTrack: active.coalesceTrack, actionTime: active.actionTime,
          },
        });
      }
    } finally {
      rows.close();
    }
    return { throughSequence: throughSequence, state: state };
  }

  private async replaceHistoryCheckpoint(noteId: string, throughSequence: number,
    state: PersistentHistoryState): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('history_checkpoint');
    predicates.equalTo('note_id', noteId);
    await this.store.delete(predicates);
    await this.store.insert('history_checkpoint', {
      'note_id': noteId,
      'through_sequence': throughSequence,
      'legacy_operation_count': state.legacyOperationCount,
      'created_time': Date.now(),
    });
    await this.insertCheckpointStack(noteId, UNDO_STACK_KIND, state.undo);
    await this.insertCheckpointStack(noteId, REDO_STACK_KIND, state.redo);
  }

  private async insertCheckpointStack(noteId: string, stackKind: number,
    actions: PersistentHistoryAction[]): Promise<void> {
    for (let stackIndex: number = 0; stackIndex < actions.length; stackIndex++) {
      const action: PersistentHistoryAction = actions[stackIndex];
      const metadata: HistoryMetadata = {
        actionId: action.actionId, effect: HistoryEffect.PUSH,
        coalesceTrack: action.coalesceTrack, actionTime: action.actionTime,
      };
      validateHistoryMetadata(metadata);
      if (action.operations.length === 0) {
        throw new Error('history checkpoint action has no operations');
      }
      await this.store.insert('history_checkpoint_action', {
        'note_id': noteId, 'stack_kind': stackKind, 'stack_index': stackIndex,
        'action_id': action.actionId, 'coalesce_track': action.coalesceTrack,
        'action_time': action.actionTime,
      });
      for (let operationIndex: number = 0; operationIndex < action.operations.length; operationIndex++) {
        const operation: Op = action.operations[operationIndex];
        if (operation.noteId !== noteId || operation.history === undefined ||
          operation.history.effect !== HistoryEffect.PUSH ||
          operation.history.actionId !== action.actionId ||
          operation.history.coalesceTrack !== action.coalesceTrack ||
          operation.history.actionTime !== action.actionTime) {
          throw new Error('history checkpoint operation contradicts its action');
        }
        await this.store.insert('history_checkpoint_operation', {
          'note_id': noteId, 'stack_kind': stackKind, 'stack_index': stackIndex,
          'operation_index': operationIndex, 'op_id': operation.opId,
          'op_type': operation.opType, 'payload': operation.payload, 'client_time': operation.clientTime,
        });
      }
    }
  }

  private async getLatestSequence(noteId: string): Promise<number> {
    const resultSet = await this.store.querySql(
      'SELECT MAX(sequence) AS max_sequence FROM operation_log WHERE note_id = ?', [noteId]);
    try {
      if (!resultSet.goToFirstRow()) {
        throw new Error('operation sequence query returned no aggregate row');
      }
      const column: number = resultSet.getColumnIndex('max_sequence');
      return resultSet.isColumnNull(column) ? 0 : resultSet.getLong(column);
    } finally {
      resultSet.close();
    }
  }

  private async validateCheckpointSequence(noteId: string, throughSequence: number): Promise<void> {
    const resultSet = await this.store.querySql(
      'SELECT note_id FROM operation_log WHERE sequence = ?', [throughSequence]);
    try {
      if (!resultSet.goToFirstRow() ||
        resultSet.getString(resultSet.getColumnIndex('note_id')) !== noteId) {
        throw new Error('history checkpoint sequence is not retained for this note');
      }
    } finally {
      resultSet.close();
    }
  }

  private async removeUnreferencedDeleteCheckpoints(noteId: string,
    state: PersistentHistoryState): Promise<number> {
    const retained: Set<string> = new Set<string>();
    for (const action of state.undo) {
      retained.add(action.actionId);
    }
    for (const action of state.redo) {
      retained.add(action.actionId);
    }
    const rows = await this.store.querySql(
      'SELECT action_id FROM page_delete_checkpoint WHERE note_id = ?', [noteId]);
    const obsolete: string[] = [];
    try {
      while (rows.goToNextRow()) {
        const actionId: string = rows.getString(rows.getColumnIndex('action_id'));
        if (!retained.has(actionId)) {
          obsolete.push(actionId);
        }
      }
    } finally {
      rows.close();
    }
    for (const actionId of obsolete) {
      const predicates = new relationalStore.RdbPredicates('page_delete_checkpoint');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('action_id', actionId);
      const deleted: number = await this.store.delete(predicates);
      if (deleted !== 1) {
        throw new Error('delete checkpoint cleanup affected an unexpected row count');
      }
    }
    return obsolete.length;
  }
}

function readOperationRow(resultSet: relationalStore.ResultSet): Op {
  const opTimestamp: number = resultSet.getLong(resultSet.getColumnIndex('op_timestamp'));
  const editorSiteId: number = resultSet.getLong(resultSet.getColumnIndex('editor_site_id'));
  const op: Op = {
    opId: resultSet.getString(resultSet.getColumnIndex('op_id')),
    noteId: resultSet.getString(resultSet.getColumnIndex('note_id')),
    opType: resultSet.getLong(resultSet.getColumnIndex('op_type')),
    payload: resultSet.getBlob(resultSet.getColumnIndex('payload')),
    clientTime: resultSet.getLong(resultSet.getColumnIndex('client_time')),
    opTimestamp: opTimestamp,
    editorSiteId: editorSiteId,
    uploadImmediately: resultSet.getLong(resultSet.getColumnIndex('upload_immediately')) === 1,
  };
  validateOperationIdentity({ timestamp: opTimestamp, siteId: editorSiteId });
  const actionColumn: number = resultSet.getColumnIndex('action_id');
  if (!resultSet.isColumnNull(actionColumn)) {
    ensureHistoryColumnsArePresent(resultSet);
    op.history = {
      actionId: resultSet.getString(actionColumn),
      effect: resultSet.getLong(resultSet.getColumnIndex('history_effect')),
      coalesceTrack: resultSet.getLong(resultSet.getColumnIndex('coalesce_track')),
      actionTime: resultSet.getLong(resultSet.getColumnIndex('action_time')),
    };
    validateHistoryMetadata(op.history);
  } else {
    ensureLegacyHistoryColumnsAreNull(resultSet);
  }
  return op;
}

async function readNoteSyncMetadata(store: relationalStore.RdbStore,
  noteId: string): Promise<OpSyncMetadata> {
  const rows = await store.querySql(
    `SELECT editor_site_id, editor_id, creator_id, created_at, updated_at, synced_op_count,
      max_op_timestamp, max_server_time, schema_version, uploaded_through_sequence,
      acked_through_sequence
     FROM note_sync_metadata WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('note sync metadata is missing');
    }
    const serverColumn: number = rows.getColumnIndex('max_server_time');
    const metadata: OpSyncMetadata = {
      noteId: noteId,
      editorSiteId: rows.getLong(rows.getColumnIndex('editor_site_id')),
      editorId: rows.getString(rows.getColumnIndex('editor_id')),
      creatorId: rows.getString(rows.getColumnIndex('creator_id')),
      createdAt: rows.getLong(rows.getColumnIndex('created_at')),
      updatedAt: rows.getLong(rows.getColumnIndex('updated_at')),
      syncedOpCount: rows.getLong(rows.getColumnIndex('synced_op_count')),
      maxOpTimestamp: rows.getLong(rows.getColumnIndex('max_op_timestamp')),
      maxServerTime: rows.isColumnNull(serverColumn) ? null : rows.getLong(serverColumn),
      schemaVersion: rows.getLong(rows.getColumnIndex('schema_version')),
      uploadedThroughSequence: rows.getLong(rows.getColumnIndex('uploaded_through_sequence')),
      ackedThroughSequence: rows.getLong(rows.getColumnIndex('acked_through_sequence')),
    };
    validateOperationIdentity({ timestamp: metadata.maxOpTimestamp, siteId: metadata.editorSiteId });
    if (metadata.editorId.length === 0 || metadata.creatorId.length === 0 ||
      !Number.isSafeInteger(metadata.createdAt) || metadata.createdAt < 0 ||
      !Number.isSafeInteger(metadata.updatedAt) || metadata.updatedAt < 0 ||
      !Number.isSafeInteger(metadata.syncedOpCount) || metadata.syncedOpCount < 0 ||
      !Number.isSafeInteger(metadata.schemaVersion) || metadata.schemaVersion < 1 ||
      (metadata.maxServerTime !== null &&
        (!Number.isSafeInteger(metadata.maxServerTime) || metadata.maxServerTime < 0)) ||
      !Number.isSafeInteger(metadata.uploadedThroughSequence) ||
      !Number.isSafeInteger(metadata.ackedThroughSequence) || metadata.ackedThroughSequence < 0 ||
      metadata.ackedThroughSequence > metadata.uploadedThroughSequence) {
      throw new Error('note sync watermarks are corrupt');
    }
    return metadata;
  } finally {
    rows.close();
  }
}

export async function appendOperation(store: relationalStore.RdbStore, op: Op): Promise<void> {
  if (op.opId.length === 0 || op.noteId.length === 0 || !Number.isSafeInteger(op.clientTime) ||
    op.clientTime < 0 || op.opTimestamp === undefined || op.editorSiteId === undefined) {
    throw new Error('operation identity or timestamp is invalid');
  }
  const identity: OperationIdentity = { timestamp: op.opTimestamp, siteId: op.editorSiteId };
  validateOperationIdentity(identity);
  if (op.opId !== encodeOperationId(identity)) {
    throw new Error('operation ID does not match its original clock identity');
  }
  const bucket: relationalStore.ValuesBucket = {
    'note_id': op.noteId,
    'op_id': op.opId,
    'op_type': op.opType,
    'payload': op.payload,
    'client_time': op.clientTime,
    'op_timestamp': op.opTimestamp,
    'editor_site_id': op.editorSiteId,
    'upload_immediately': op.uploadImmediately === true ? 1 : 0,
  };
  if (op.history !== undefined) {
    validateHistoryMetadata(op.history);
    bucket['action_id'] = op.history.actionId;
    bucket['history_effect'] = op.history.effect;
    bucket['coalesce_track'] = op.history.coalesceTrack;
    bucket['action_time'] = op.history.actionTime;
  }
  // Deliberately use INSERT without conflict replacement: duplicate op IDs are corruption.
  await store.insert('operation_log', bucket);
}

function ensureLegacyHistoryColumnsAreNull(resultSet: relationalStore.ResultSet): void {
  const columns: string[] = ['history_effect', 'coalesce_track', 'action_time'];
  for (const name of columns) {
    if (!resultSet.isColumnNull(resultSet.getColumnIndex(name))) {
      throw new Error('operation has partial history metadata');
    }
  }
}

function ensureHistoryColumnsArePresent(resultSet: relationalStore.ResultSet): void {
  const columns: string[] = ['history_effect', 'coalesce_track', 'action_time'];
  for (const name of columns) {
    if (resultSet.isColumnNull(resultSet.getColumnIndex(name))) {
      throw new Error('operation has partial history metadata');
    }
  }
}

export function monotonicOperationTime(lastClientTime: number | null, wallClockTime: number): number {
  if (!Number.isSafeInteger(wallClockTime) || wallClockTime < 0 ||
    (lastClientTime !== null && (!Number.isSafeInteger(lastClientTime) || lastClientTime < 0))) {
    throw new Error('operation clock value is invalid');
  }
  if (lastClientTime === null) {
    return wallClockTime;
  }
  if (lastClientTime >= Number.MAX_SAFE_INTEGER) {
    throw new Error('operation client time is exhausted');
  }
  return Math.max(wallClockTime, lastClientTime + 1);
}

export async function allocateOperationClientTime(store: relationalStore.RdbStore,
  noteId: string, wallClockTime: number = Date.now()): Promise<number> {
  const resultSet = await store.querySql(
    'SELECT MAX(client_time) AS max_client_time FROM operation_log WHERE note_id = ?', [noteId]);
  try {
    if (!resultSet.goToFirstRow()) {
      throw new Error('operation time query returned no aggregate row');
    }
    const column: number = resultSet.getColumnIndex('max_client_time');
    const last: number | null = resultSet.isColumnNull(column) ? null : resultSet.getLong(column);
    return monotonicOperationTime(last, wallClockTime);
  } finally {
    resultSet.close();
  }
}

export async function allocateOperationIdentity(store: relationalStore.RdbStore,
  noteId: string, wallClockTime: number = Date.now()): Promise<AllocatedOperationIdentity> {
  if (noteId.length === 0 || !Number.isSafeInteger(wallClockTime) || wallClockTime < 0) {
    throw new Error('operation identity requires a note ID');
  }
  await ensureNoteSyncMetadata(store, noteId);
  const resultSet = await store.querySql(
    `SELECT editor_site_id, max_op_timestamp FROM note_sync_metadata WHERE note_id = ?`, [noteId]);
  let siteId: number = 0;
  let currentTimestamp: number = 0;
  try {
    if (!resultSet.goToFirstRow()) {
      throw new Error('note sync metadata disappeared during identity allocation');
    }
    siteId = resultSet.getLong(resultSet.getColumnIndex('editor_site_id'));
    currentTimestamp = resultSet.getLong(resultSet.getColumnIndex('max_op_timestamp'));
  } finally {
    resultSet.close();
  }
  const timestamp: number = nextOperationTimestamp(currentTimestamp);
  const clientTime: number = await allocateOperationClientTime(store, noteId, wallClockTime);
  const predicates = new relationalStore.RdbPredicates('note_sync_metadata');
  predicates.equalTo('note_id', noteId);
  predicates.equalTo('max_op_timestamp', currentTimestamp);
  const updated: number = await store.update({
    'max_op_timestamp': timestamp,
    'updated_at': clientTime,
  }, predicates);
  if (updated !== 1) {
    throw new Error('operation clock changed concurrently');
  }
  const identity: OperationIdentity = { timestamp: timestamp, siteId: siteId };
  return {
    timestamp: timestamp,
    siteId: siteId,
    opId: encodeOperationId(identity),
    clientTime: clientTime,
  };
}

export async function initializeImportedNoteSyncMetadata(store: relationalStore.RdbStore,
  noteId: string, legacyId: string | null, createdAt: number, updatedAt: number): Promise<void> {
  if (noteId.length === 0 || (legacyId !== null && legacyId.length === 0) ||
    !Number.isSafeInteger(createdAt) || createdAt < 0 ||
    !Number.isSafeInteger(updatedAt) || updatedAt < 0) {
    throw new Error('imported note sync identity is invalid');
  }
  const identity = await store.querySql(
    'SELECT editor_id FROM local_editor_identity WHERE singleton = 1');
  let editorId: string = '';
  try {
    if (!identity.goToFirstRow()) {
      throw new Error('local editor identity is missing');
    }
    editorId = identity.getString(identity.getColumnIndex('editor_id'));
    if (editorId.length === 0) {
      throw new Error('local editor identity is empty');
    }
  } finally {
    identity.close();
  }
  await store.insert('note_sync_metadata', {
    'note_id': noteId,
    'legacy_id': legacyId,
    'editor_site_id': 0,
    'editor_id': editorId,
    'creator_id': editorId,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'synced_op_count': 0,
    'max_op_timestamp': 0,
    'schema_version': 1,
    'uploaded_through_sequence': 0,
    'acked_through_sequence': 0,
  });
}

async function ensureNoteSyncMetadata(store: relationalStore.RdbStore, noteId: string): Promise<void> {
  const existing = await store.querySql(
    'SELECT note_id FROM note_sync_metadata WHERE note_id = ?', [noteId]);
  try {
    if (existing.goToFirstRow()) {
      return;
    }
  } finally {
    existing.close();
  }
  const source = await store.querySql(
    `SELECT note.created_at, note.updated_at, identity.editor_id,
      COALESCE((SELECT MAX(op_timestamp) FROM operation_log WHERE note_id = note.id), 0) AS max_timestamp
     FROM note_meta note CROSS JOIN local_editor_identity identity
     WHERE note.id = ? AND identity.singleton = 1`, [noteId]);
  try {
    if (!source.goToFirstRow()) {
      throw new Error('cannot initialize sync metadata for a missing note or editor identity');
    }
    const editorId: string = source.getString(source.getColumnIndex('editor_id'));
    await store.insert('note_sync_metadata', {
      'note_id': noteId,
      'editor_site_id': 0,
      'editor_id': editorId,
      'creator_id': editorId,
      'created_at': source.getLong(source.getColumnIndex('created_at')),
      'updated_at': source.getLong(source.getColumnIndex('updated_at')),
      'max_op_timestamp': source.getLong(source.getColumnIndex('max_timestamp')),
      'schema_version': 1,
      'uploaded_through_sequence': 0,
      'acked_through_sequence': 0,
    });
  } finally {
    source.close();
  }
}

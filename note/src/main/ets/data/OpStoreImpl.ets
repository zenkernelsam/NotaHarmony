import { relationalStore } from '@kit.ArkData';
import { Op } from '../core/model/OpTypes';
import { OpStore } from '../core/op/OpStore';
import { DatabaseManager } from './DatabaseManager';

export class OpStoreImpl implements OpStore {
  private store: relationalStore.RdbStore;

  constructor(db: DatabaseManager) {
    this.store = db.getStore();
  }

  async appendOp(op: Op): Promise<void> {
    await appendOperation(this.store, op);
  }

  async getOps(noteId: string): Promise<Op[]> {
    return this.queryOps(
      `SELECT op_id, note_id, op_type, payload, client_time FROM operation_log
       WHERE note_id = ? ORDER BY client_time, sequence`, [noteId]);
  }

  async getOpsSince(noteId: string, sinceTime: number): Promise<Op[]> {
    return this.queryOps(
      `SELECT op_id, note_id, op_type, payload, client_time FROM operation_log
       WHERE note_id = ? AND client_time > ? ORDER BY client_time, sequence`, [noteId, sinceTime]);
  }

  async deleteOps(noteId: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('operation_log');
    predicates.equalTo('note_id', noteId);
    await this.store.delete(predicates);
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

  private async queryOps(sql: string, args: relationalStore.ValueType[]): Promise<Op[]> {
    const resultSet = await this.store.querySql(sql, args);
    const result: Op[] = [];
    try {
      while (resultSet.goToNextRow()) {
        result.push({
          opId: resultSet.getString(resultSet.getColumnIndex('op_id')),
          noteId: resultSet.getString(resultSet.getColumnIndex('note_id')),
          opType: resultSet.getLong(resultSet.getColumnIndex('op_type')),
          payload: resultSet.getBlob(resultSet.getColumnIndex('payload')),
          clientTime: resultSet.getLong(resultSet.getColumnIndex('client_time')),
        });
      }
    } finally {
      resultSet.close();
    }
    return result;
  }
}

export async function appendOperation(store: relationalStore.RdbStore, op: Op): Promise<void> {
  if (op.opId.length === 0 || op.noteId.length === 0 || !Number.isSafeInteger(op.clientTime) ||
    op.clientTime < 0) {
    throw new Error('operation identity or timestamp is invalid');
  }
  const bucket: relationalStore.ValuesBucket = {
    'note_id': op.noteId,
    'op_id': op.opId,
    'op_type': op.opType,
    'payload': op.payload,
    'client_time': op.clientTime,
  };
  // Deliberately use INSERT without conflict replacement: duplicate op IDs are corruption.
  await store.insert('operation_log', bucket);
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

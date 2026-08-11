import { relationalStore } from '@kit.ArkData';
import { OperationIdentity, validateOperationIdentity } from './OperationIdentity';
import { parseOriginalSyncedOperationEnvelope } from './OriginalSyncedOperationFlatBuffer';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';

export interface OriginalAppliedOperationTime extends OperationIdentity {
  noteId: string;
  clientTime: string;
  audioTime: string | null;
  effectiveAudioTime: string;
  payloadType: number;
}

export interface OriginalOperationTimeCandidate extends OperationIdentity {
  noteId: string;
  clientTime: string;
  audioTime: string | null;
  payloadType: number;
}

export interface OriginalOperationTimeDatabase {
  getStore(): relationalStore.RdbStore;
}

export async function persistOriginalAppliedOperationTime(store: relationalStore.RdbStore,
  operation: OriginalOperationTimeCandidate): Promise<void> {
  validateOperationTime(operation);
  const rows = await store.querySql(
    `SELECT client_time, audio_time, payload_type FROM original_applied_operation_time
     WHERE note_id = ? AND op_timestamp = ? AND op_site_id = ?`,
    [operation.noteId, operation.timestamp, operation.siteId]);
  try {
    if (rows.goToFirstRow()) {
      const audioColumn: number = rows.getColumnIndex('audio_time');
      const storedAudioTime: string | null = rows.isColumnNull(audioColumn) ? null :
        rows.getString(audioColumn);
      if (rows.getString(rows.getColumnIndex('client_time')) !== operation.clientTime ||
        storedAudioTime !== operation.audioTime ||
        rows.getLong(rows.getColumnIndex('payload_type')) !== operation.payloadType) {
        throw new Error('original applied operation time identity conflict');
      }
      return;
    }
  } finally {
    rows.close();
  }
  const values: relationalStore.ValuesBucket = {
    'note_id': operation.noteId,
    'op_timestamp': operation.timestamp,
    'op_site_id': operation.siteId,
    'client_time': operation.clientTime,
    'payload_type': operation.payloadType,
  };
  if (operation.audioTime !== null) {
    values['audio_time'] = operation.audioTime;
  }
  await store.insert('original_applied_operation_time', values);
}

export async function backfillOriginalAppliedOperationTimes(
  store: relationalStore.RdbStore): Promise<void> {
  const rows = await store.querySql(
    `SELECT inbox.note_id, inbox.op_timestamp, inbox.editor_site_id, inbox.client_time,
            inbox.server_time, inbox.payload_type, inbox.raw_operation
     FROM synced_operation_inbox inbox
     LEFT JOIN original_applied_operation_time timing
       ON timing.note_id = inbox.note_id AND timing.op_timestamp = inbox.op_timestamp
       AND timing.op_site_id = inbox.editor_site_id
     WHERE inbox.state = 2 AND timing.note_id IS NULL`);
  const pending: OriginalOperationTimeCandidate[] = [];
  try {
    while (rows.goToNextRow()) {
      const raw: Uint8Array = rows.getBlob(rows.getColumnIndex('raw_operation'));
      const envelope = parseOriginalSyncedOperationEnvelope(raw);
      const timestamp: number = rows.getLong(rows.getColumnIndex('op_timestamp'));
      const siteId: number = rows.getLong(rows.getColumnIndex('editor_site_id'));
      if (envelope.timestamp !== timestamp || envelope.siteId !== siteId ||
        envelope.clientTime !== rows.getString(rows.getColumnIndex('client_time')) ||
        envelope.serverTime !== rows.getString(rows.getColumnIndex('server_time')) ||
        envelope.payloadType !== rows.getLong(rows.getColumnIndex('payload_type'))) {
        throw new Error('applied operation time backfill found mismatched envelope metadata');
      }
      pending.push({
        noteId: rows.getString(rows.getColumnIndex('note_id')),
        timestamp: timestamp,
        siteId: siteId,
        clientTime: envelope.clientTime,
        audioTime: envelope.audioTime,
        payloadType: envelope.payloadType,
      });
    }
  } finally {
    rows.close();
  }
  for (const operation of pending) {
    await persistOriginalAppliedOperationTime(store, operation);
  }
}

export class OriginalOperationAudioTimeStore {
  private store: relationalStore.RdbStore;

  constructor(db: OriginalOperationTimeDatabase) {
    this.store = db.getStore();
  }

  async listForNote(noteId: string): Promise<OriginalAppliedOperationTime[]> {
    if (noteId.length === 0) {
      throw new Error('original operation audio-time note id is invalid');
    }
    const rows = await this.store.querySql(
      `SELECT note_id, op_timestamp, op_site_id, client_time, audio_time, payload_type
       FROM original_applied_operation_time WHERE note_id = ?
       ORDER BY length(COALESCE(audio_time, client_time)), COALESCE(audio_time, client_time),
         op_timestamp, op_site_id`, [noteId]);
    const result: OriginalAppliedOperationTime[] = [];
    try {
      while (rows.goToNextRow()) {
        const audioColumn: number = rows.getColumnIndex('audio_time');
        const audioTime: string | null = rows.isColumnNull(audioColumn) ? null :
          rows.getString(audioColumn);
        const clientTime: string = rows.getString(rows.getColumnIndex('client_time'));
        result.push({
          noteId: rows.getString(rows.getColumnIndex('note_id')),
          timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('op_site_id')),
          clientTime: clientTime,
          audioTime: audioTime,
          effectiveAudioTime: audioTime === null ? clientTime : audioTime,
          payloadType: rows.getLong(rows.getColumnIndex('payload_type')),
        });
      }
    } finally {
      rows.close();
    }
    return result;
  }
}

function validateOperationTime(operation: OriginalOperationTimeCandidate): void {
  if (operation.noteId.length === 0 || !Number.isSafeInteger(operation.payloadType) ||
    operation.payloadType < 1 || operation.payloadType > 31) {
    throw new Error('original applied operation time is invalid');
  }
  validateOperationIdentity(operation);
  validateUnsignedLongDecimal(operation.clientTime);
  if (operation.audioTime !== null) {
    validateUnsignedLongDecimal(operation.audioTime);
  }
}

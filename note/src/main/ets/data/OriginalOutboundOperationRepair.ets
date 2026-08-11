import { relationalStore } from '@kit.ArkData';
import { OpType } from '../core/model/OpTypes';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import { decodeOriginalCreateRecordingTable } from './OriginalRecordingOperation';
import {
  OriginalFlatBufferTableReader, OriginalOperationEnvelope, parseOriginalOperationEnvelope,
} from './OriginalSyncedOperationFlatBuffer';

interface LegacyOutboundRow {
  sequence: number;
  noteId: string;
  timestamp: number;
  siteId: number;
  clientTime: string;
  audioTime: string | null;
  payloadType: number;
  payload: Uint8Array;
}

// Phase 98 could materialize CREATE_RECORDING from its child and then journal that child. The
// later page/Ink writers deferred before append, so they cannot have committed legacy rows.
export async function repairLegacyOriginalOutboundEnvelopes(
  store: relationalStore.RdbStore): Promise<number> {
  const rows = await store.querySql(
    `SELECT operation.sequence, operation.note_id, operation.op_type, operation.payload,
            operation.client_time, operation.op_timestamp, operation.editor_site_id,
            timing.audio_time
       FROM operation_log operation
       LEFT JOIN original_applied_operation_time timing
         ON timing.note_id = operation.note_id
        AND timing.op_timestamp = operation.op_timestamp
        AND timing.op_site_id = operation.editor_site_id
      WHERE operation.op_type = ?
      ORDER BY operation.sequence`, [OpType.ORIGINAL_CREATE_RECORDING]);
  const storedRows: LegacyOutboundRow[] = [];
  try {
    while (rows.goToNextRow()) {
      storedRows.push(readRow(rows));
    }
  } finally {
    rows.close();
  }
  let repaired: number = 0;
  for (const row of storedRows) {
    let envelope: OriginalOperationEnvelope | null = null;
    try {
      envelope = parseOriginalOperationEnvelope(row.payload);
    } catch (_error) {
      envelope = null;
    }
    if (envelope !== null) {
      if (envelope.timestamp !== row.timestamp || envelope.siteId !== row.siteId ||
        envelope.clientTime !== row.clientTime || envelope.payloadType !== row.payloadType ||
        (envelope.serverTime !== null && envelope.serverTime !== '0') ||
        envelope.audioTime !== row.audioTime) {
        throw new Error('stored original outbound envelope disagrees with its operation row');
      }
      continue;
    }
    decodeOriginalCreateRecordingTable(OriginalFlatBufferTableReader.fromRoot(row.payload));
    const wrapped: Uint8Array = encodeOriginalOperationEnvelope({
      identity: { timestamp: row.timestamp, siteId: row.siteId },
      clientTime: row.clientTime, serverTime: null, audioTime: row.audioTime,
      payloadType: row.payloadType,
    }, row.payload);
    const predicates = new relationalStore.RdbPredicates('operation_log');
    predicates.equalTo('sequence', row.sequence);
    if (await store.update({ 'payload': wrapped }, predicates) !== 1) {
      throw new Error('legacy original outbound operation disappeared during repair');
    }
    repaired++;
  }
  return repaired;
}

function readRow(rows: relationalStore.ResultSet): LegacyOutboundRow {
  const opType: number = rows.getLong(rows.getColumnIndex('op_type'));
  return {
    sequence: rows.getLong(rows.getColumnIndex('sequence')),
    noteId: rows.getString(rows.getColumnIndex('note_id')),
    timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
    siteId: rows.getLong(rows.getColumnIndex('editor_site_id')),
    clientTime: rows.getLong(rows.getColumnIndex('client_time')).toString(),
    audioTime: rows.isColumnNull(rows.getColumnIndex('audio_time')) ? null :
      rows.getString(rows.getColumnIndex('audio_time')),
    payloadType: payloadTypeForOpType(opType),
    payload: rows.getBlob(rows.getColumnIndex('payload')),
  };
}

function payloadTypeForOpType(opType: number): number {
  if (opType === OpType.ORIGINAL_CREATE_RECORDING) {
    return 5;
  }
  throw new Error('legacy original outbound operation type is unsupported');
}

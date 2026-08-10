import { relationalStore } from '@kit.ArkData';
import { compareOperationIdentity, OperationIdentity } from './OperationIdentity';

export interface OriginalEntityVisibilityWinner extends OperationIdentity {
  deleted: boolean;
}

export function originalEntityVisibilityUpdateApplies(operation: OperationIdentity,
  deleted: boolean, winner: OriginalEntityVisibilityWinner | null): boolean {
  if (winner === null) {
    return true;
  }
  const comparison: number = compareOperationIdentity(operation, winner);
  if (comparison === 0 && winner.deleted !== deleted) {
    throw new Error('original entity visibility identity conflicts with persisted value');
  }
  return comparison > 0;
}

export async function readOriginalEntityVisibilityWinner(store: relationalStore.RdbStore,
  noteId: string, entity: OperationIdentity): Promise<OriginalEntityVisibilityWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, deleted FROM original_entity_visibility_winner
     WHERE note_id = ? AND entity_timestamp = ? AND entity_site_id = ?`,
    [noteId, entity.timestamp, entity.siteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      deleted: rows.getLong(rows.getColumnIndex('deleted')) === 1,
    };
  } finally {
    rows.close();
  }
}

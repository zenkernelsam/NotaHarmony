// T-025 元素持久化（MVP 简化：JSON 序列化存 client_op 表，kind 区分笔画/文本框）
// 每次变更全量重写（数据量小，MVP 可靠优先）；全部方法异常安全
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { TextBlockElement } from '../core/model/ElementTypes';
import { DatabaseManager } from './DatabaseManager';

// 持久化元素（带类型标记）
export interface PersistedElement {
  kind: string;  // 'stroke' | 'text'
  data: StrokeElementData | TextBlockElement;
}

export interface LoadedElements {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
}

export class StrokePersistence {
  private store: relationalStore.RdbStore | null = null;

  initialize(db: DatabaseManager): void {
    this.store = db.getStore();
  }

  isReady(): boolean {
    return this.store !== null;
  }

  // 保存笔记全部元素（清空重写）
  async saveElements(noteId: string, strokes: StrokeElementData[],
    textBlocks: TextBlockElement[]): Promise<void> {
    if (this.store === null) {
      return;
    }
    const store: relationalStore.RdbStore = this.store;
    try {
      const del = new relationalStore.RdbPredicates('client_op');
      del.equalTo('note_id', noteId);
      await store.delete(del);
      const now: number = Date.now();
      // T-040 审核修复：同批元素的 client_time 用递增序号保证加载顺序稳定
      // （原实现全部相同时间戳，SQL 对相同 key 不保证顺序 → 图层顺序可能错乱）
      let seq: number = 0;
      // 先笔画后文本（保持顺序稳定）
      for (const stroke of strokes) {
        const payload: PersistedElement = { kind: 'stroke', data: stroke };
        const bucket: relationalStore.ValuesBucket = {
          'op_id': stroke.id,
          'note_id': noteId,
          'op_type': 10,  // OpType.INSERT_ELEMENTS
          'payload': this.stringToBytes(JSON.stringify(payload)),
          'client_time': now + seq,
        };
        seq++;
        await store.insert('client_op', bucket);
      }
      for (const text of textBlocks) {
        const payload: PersistedElement = { kind: 'text', data: text };
        const bucket: relationalStore.ValuesBucket = {
          'op_id': text.id,
          'note_id': noteId,
          'op_type': 10,
          'payload': this.stringToBytes(JSON.stringify(payload)),
          'client_time': now + seq,
        };
        seq++;
        await store.insert('client_op', bucket);
      }
    } catch (e) {
      console.error(`saveElements failed: ${JSON.stringify(e)}`);
    }
  }

  // 加载笔记全部元素
  async loadElements(noteId: string): Promise<LoadedElements> {
    const result: LoadedElements = { strokes: [], textBlocks: [] };
    if (this.store === null) {
      return result;
    }
    const store: relationalStore.RdbStore = this.store;
    try {
      const predicates = new relationalStore.RdbPredicates('client_op');
      predicates.equalTo('note_id', noteId);
      predicates.orderByAsc('client_time');
      const resultSet = await store.query(predicates);
      while (resultSet.goToNextRow()) {
        const bytes: Uint8Array = resultSet.getBlob(resultSet.getColumnIndex('payload'));
        const json: string = this.bytesToString(bytes);
        try {
          const parsed = JSON.parse(json) as PersistedElement;
          if (parsed.kind === 'stroke') {
            result.strokes.push(parsed.data as StrokeElementData);
          } else if (parsed.kind === 'text') {
            result.textBlocks.push(parsed.data as TextBlockElement);
          }
        } catch (e) {
          // 跳过损坏记录
        }
      }
      resultSet.close();
    } catch (e) {
      console.error(`loadElements failed: ${JSON.stringify(e)}`);
    }
    return result;
  }

  private stringToBytes(text: string): Uint8Array {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(text);
  }

  private bytesToString(bytes: Uint8Array): string {
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decode(bytes);
  }
}

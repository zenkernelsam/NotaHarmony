import { PageInfo } from '../core/model/NoteTypes';
import { SearchSourceElement } from './SearchIndexPolicy';

export interface PageDeleteCheckpointElement extends SearchSourceElement {
  revision: number;
  elementOrder: number;
}

export interface PageDeleteCheckpoint {
  noteId: string;
  actionId: string;
  page: PageInfo;
  contentRevision: number;
  indexedRevision: number | null;
  createdTime: number;
  elements: PageDeleteCheckpointElement[];
}

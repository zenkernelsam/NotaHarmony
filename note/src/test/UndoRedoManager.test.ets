import { describe, it, expect } from '@ohos/hypium';
import {
  AddStrokeAction, UndoableAction, UndoableActionType, UndoRedoManager,
} from '../main/ets/rendering/UndoRedoManager';

function makeAction(pageId: string): AddStrokeAction {
  return {
    type: UndoableActionType.ADD_STROKE,
    pageId: pageId,
    addedStrokes: [],
  };
}

export default function undoRedoManagerTest() {
  describe('UndoRedoManager', () => {
    it('does not move history until the caller commits a successful apply', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: UndoableAction = makeAction('page-2');
      manager.push(action);

      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canUndo()).assertTrue();
      expect(manager.canRedo()).assertFalse();

      // A failed document apply performs no commit, so the same action remains available.
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canRedo()).assertFalse();
    });

    it('rejects a stale commit and moves the exact action symmetrically', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager();
      const action: UndoableAction = makeAction('page-1');
      const stale: UndoableAction = makeAction('page-1');
      manager.push(action);

      expect(manager.commitUndo(stale)).assertFalse();
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.commitUndo(action)).assertTrue();
      expect(manager.canUndo()).assertFalse();
      expect(manager.peekRedo() === action).assertTrue();
      expect(manager.commitRedo(action)).assertTrue();
      expect(manager.peekUndo() === action).assertTrue();
      expect(manager.canRedo()).assertFalse();
    });

    it('uses the configured capacity without changing action order', 0, () => {
      const manager: UndoRedoManager = new UndoRedoManager(2);
      const first: UndoableAction = makeAction('page-1');
      const second: UndoableAction = makeAction('page-2');
      const third: UndoableAction = makeAction('page-3');
      manager.push(first);
      manager.push(second);
      manager.push(third);

      expect(manager.peekUndo() === third).assertTrue();
      expect(manager.commitUndo(third)).assertTrue();
      expect(manager.peekUndo() === second).assertTrue();
      expect(manager.commitUndo(second)).assertTrue();
      expect(manager.peekUndo() === null).assertTrue();
    });
  });
}

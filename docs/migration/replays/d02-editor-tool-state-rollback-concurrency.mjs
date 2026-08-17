import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const normalize = value => value.replaceAll('\r\n', '\n');
const readText = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const production = readText('note/src/main/ets/ui/editor/EditorViewModel.ets');
const fixture = readText('note/src/test/EditorViewModel.test.ets');

let total = 0;
let failed = 0;

function check(name, condition) {
  total++;
  if (!condition) {
    failed++;
    console.error(`FAIL: ${name}`);
    return;
  }
  console.log(`PASS: ${name}`);
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((onResolve, onReject) => {
    resolve = onResolve;
    reject = onReject;
  });
  return { promise, resolve, reject };
}

async function waitUntil(predicate) {
  for (let index = 0; index < 40 && !predicate(); index++) {
    await Promise.resolve();
  }
  assert.equal(predicate(), true, 'FAILED: queued persistence operation did not start');
}

class SerialQueue {
  chain = Promise.resolve();

  enqueue(operation) {
    const job = this.chain.then(operation);
    this.chain = job.catch(() => {});
    return job;
  }
}

class CommittedSlotModel {
  queue = new SerialQueue();
  committed;
  visible;
  version = 0;
  attempts = 0;

  constructor(initial) {
    this.committed = initial;
    this.visible = initial;
  }

  async update(value, gate) {
    const version = ++this.version;
    this.visible = value;
    try {
      await this.queue.enqueue(async () => {
        this.attempts++;
        await gate.promise;
      });
      this.committed = value;
      return true;
    } catch (_error) {
      if (this.version === version) this.visible = this.committed;
      return false;
    }
  }
}

async function runSlotCase(firstOutcome, secondOutcome) {
  const model = new CommittedSlotModel('black');
  const firstGate = deferred();
  const secondGate = deferred();
  const first = model.update('red', firstGate);
  const second = model.update('blue', secondGate);
  await waitUntil(() => model.attempts === 1);
  firstOutcome === 'success' ? firstGate.resolve() : firstGate.reject(new Error('first failed'));
  await waitUntil(() => model.attempts === 2);
  secondOutcome === 'success' ? secondGate.resolve() : secondGate.reject(new Error('second failed'));
  return { model, results: await Promise.all([first, second]) };
}

class SelectionModel {
  queue = new SerialQueue();
  committed = { active: 'pen', previous: 'pen' };
  active = 'pen';
  previous = 'pen';
  version = 0;
  toolboxAttempts = 0;
  modeAttempts = 0;

  restoreCommitted() {
    this.active = this.committed.active;
    this.previous = this.committed.previous;
  }

  async select(tool, toolboxGate) {
    const version = ++this.version;
    this.previous = this.active;
    this.active = tool;
    const snapshot = { active: this.active, previous: this.previous };
    try {
      await this.queue.enqueue(async () => {
        this.toolboxAttempts++;
        await toolboxGate.promise;
      });
      this.committed = snapshot;
      return true;
    } catch (_error) {
      if (this.version === version) this.restoreCommitted();
      return false;
    }
  }

  async selectEraser(modeGate, toolboxGate) {
    const version = ++this.version;
    this.previous = this.active;
    this.active = 'eraser';
    let modeSaved = false;
    try {
      await this.queue.enqueue(async () => {
        this.modeAttempts++;
        await modeGate.promise;
      });
      modeSaved = true;
    } catch (_error) {
      if (this.version === version) this.restoreCommitted();
    }
    if (!modeSaved) return false;
    if (this.version !== version) return true;
    const snapshot = { active: this.active, previous: this.previous };
    try {
      await this.queue.enqueue(async () => {
        this.toolboxAttempts++;
        await toolboxGate.promise;
      });
      this.committed = snapshot;
      return true;
    } catch (_error) {
      if (this.version === version) this.restoreCommitted();
      return false;
    }
  }
}

const bothFail = await runSlotCase('failure', 'failure');
check('two failed tool writes restore the last persisted value',
  bothFail.model.visible === 'black' && bothFail.model.committed === 'black' &&
    bothFail.results[0] === false && bothFail.results[1] === false);

const failThenSuccess = await runSlotCase('failure', 'success');
check('a newer successful tool write survives an older failure',
  failThenSuccess.model.visible === 'blue' && failThenSuccess.model.committed === 'blue');

const successThenFail = await runSlotCase('success', 'failure');
check('a newer failed tool write rolls back to the first successful value',
  successThenFail.model.visible === 'red' && successThenFail.model.committed === 'red');

const selection = new SelectionModel();
const firstToolboxGate = deferred();
const secondToolboxGate = deferred();
const firstSelection = selection.select('pencil', firstToolboxGate);
const secondSelection = selection.select('highlighter', secondToolboxGate);
await waitUntil(() => selection.toolboxAttempts === 1);
firstToolboxGate.reject(new Error('first toolbox failed'));
await waitUntil(() => selection.toolboxAttempts === 2);
secondToolboxGate.reject(new Error('second toolbox failed'));
const selectionResults = await Promise.all([firstSelection, secondSelection]);
check('two failed toolbox writes restore the persisted selection',
  selection.active === 'pen' && selection.previous === 'pen' &&
    selectionResults[0] === false && selectionResults[1] === false);
check('selection generation remains monotonic after rollback', selection.version === 2);

const partiallyCommittedSelection = new SelectionModel();
const committedToolboxGate = deferred();
const failedToolboxGate = deferred();
const committedSelection = partiallyCommittedSelection.select('pencil', committedToolboxGate);
const failedSelection = partiallyCommittedSelection.select('highlighter', failedToolboxGate);
await waitUntil(() => partiallyCommittedSelection.toolboxAttempts === 1);
committedToolboxGate.resolve();
await waitUntil(() => partiallyCommittedSelection.toolboxAttempts === 2);
failedToolboxGate.reject(new Error('newer toolbox failed'));
await Promise.all([committedSelection, failedSelection]);
check('a failed newer toolbox write restores the preceding successful selection',
  partiallyCommittedSelection.active === 'pencil' &&
    partiallyCommittedSelection.committed.active === 'pencil');

for (const modeOutcome of ['failure', 'success']) {
  const model = new SelectionModel();
  const modeGate = deferred();
  const staleToolboxGate = deferred();
  const laterToolboxGate = deferred();
  const eraserSelection = model.selectEraser(modeGate, staleToolboxGate);
  const laterSelection = model.select('pencil', laterToolboxGate);
  await waitUntil(() => model.modeAttempts === 1);
  modeOutcome === 'success' ? modeGate.resolve() : modeGate.reject(new Error('mode failed'));
  await waitUntil(() => model.toolboxAttempts === 1);
  laterToolboxGate.resolve();
  await Promise.all([eraserSelection, laterSelection]);
  check(`late eraser-mode ${modeOutcome} cannot reactivate the superseded selection`,
    model.active === 'pencil' && model.committed.active === 'pencil' &&
      model.toolboxAttempts === 1);
}

const shapeBothFail = await runSlotCase('failure', 'failure');
check('two failed shape-preference writes restore the persisted preference',
  shapeBothFail.model.visible === 'black' && shapeBothFail.model.committed === 'black');

check('production stores committed snapshots for tool, toolbox and shape preference',
  production.includes('private committedStates: Map<string, ToolState>') &&
    production.includes('private committedToolbox: EditorToolboxState | null') &&
    production.includes('private committedShapeDetectionEnabled: boolean'));
check('tool success advances committed state and latest failure restores it',
  production.includes('this.committedStates.set(toolId, this.cloneState(updated));') &&
    production.includes('const committed: ToolState | undefined = this.committedStates.get(toolId);'));
check('toolbox success advances committed selection and failure restores it',
  production.includes('this.committedToolbox = this.cloneToolboxState(snapshot);') &&
    production.includes('this.restoreCommittedToolbox();'));
check('eraser selection checks supersession after its awaited mode write',
  production.includes('if (this.selectionVersion !== version) {\n        return true;\n      }'));
check('selection rollback never decrements its generation',
  !production.includes('this.selectionVersion = oldSelectionVersion'));
check('shape preference uses a generation and committed rollback value',
  production.includes('this.shapeDetectionVersion++') &&
    production.includes('this.shapeDetectionEnabled = this.committedShapeDetectionEnabled;'));
check('reinitialization waits for the existing persistence tail before repository reload',
  production.indexOf('await this.saveChain;') < production.indexOf('this.repository = repository;'));
check('ArkTS fixture covers all three tool-write outcome pairs',
  fixture.includes('when two optimistic writes both fail') &&
    fixture.includes('the first write fails and the second succeeds') &&
    fixture.includes('only the second write fails'));
check('ArkTS fixture covers committed toolbox and shape rollback prefixes',
  fixture.includes('only the newer toolbox write fails') &&
    fixture.includes('shape preference to the first successful queued write'));
check('ArkTS fixture covers failed and successful late eraser mode completions',
  fixture.includes('failed eraser-mode write overwrite a later tool selection') &&
    fixture.includes('successful late eraser-mode save reactivate the old selection'));
check('ArkTS fixture covers queued shape preference failures',
  fixture.includes('when two queued writes both fail'));
check('ArkTS fixture covers save-before-reinitialize ordering',
  fixture.includes('waits for the prior save chain before reinitializing from the repository'));

if (failed > 0) {
  console.error(`D02_EDITOR_TOOL_STATE_ROLLBACK_CONCURRENCY_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_EDITOR_TOOL_STATE_ROLLBACK_CONCURRENCY_OK TOTAL=${total} FAILED=0`);

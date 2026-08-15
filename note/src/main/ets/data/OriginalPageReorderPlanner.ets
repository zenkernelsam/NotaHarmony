const MAX_ORIGINAL_PAGE_REORDER_COUNT: number = 10000;

export interface OriginalPageReorderPlan {
  movedPageId: string;
  predecessorPageId: string | null;
}

export function planOriginalPageReorder(currentOrder: string[], requestedOrder: string[],
  movedPageId: string): OriginalPageReorderPlan {
  if (movedPageId.length === 0 || currentOrder.length < 1 ||
    currentOrder.length > MAX_ORIGINAL_PAGE_REORDER_COUNT ||
    currentOrder.length !== requestedOrder.length) {
    throw new Error('local ModifyPage reorder identity or page count is invalid');
  }
  const currentIds: Set<string> = validateUniqueOrder(currentOrder, 'current');
  const requestedIds: Set<string> = validateUniqueOrder(requestedOrder, 'requested');
  if (!currentIds.has(movedPageId) || !requestedIds.has(movedPageId)) {
    throw new Error('local ModifyPage moved page is not present in both orders');
  }
  for (const pageId of currentOrder) {
    if (!requestedIds.has(pageId)) {
      throw new Error('local ModifyPage requested order changed page membership');
    }
  }
  if (sameStrings(currentOrder, requestedOrder)) {
    throw new Error('local ModifyPage reorder does not change page order');
  }
  const currentWithoutMoved: string[] = withoutPage(currentOrder, movedPageId);
  const requestedWithoutMoved: string[] = withoutPage(requestedOrder, movedPageId);
  if (!sameStrings(currentWithoutMoved, requestedWithoutMoved)) {
    throw new Error('local ModifyPage reorder is not one page relocation');
  }
  const targetIndex: number = findIndex(requestedOrder, movedPageId);
  if (targetIndex < 0) {
    throw new Error('local ModifyPage moved page disappeared');
  }
  return {
    movedPageId: movedPageId,
    predecessorPageId: targetIndex === 0 ? null : requestedOrder[targetIndex - 1],
  };
}

function validateUniqueOrder(order: string[], name: string): Set<string> {
  const seen: Set<string> = new Set<string>();
  for (const pageId of order) {
    if (pageId.length === 0 || seen.has(pageId)) {
      throw new Error(`local ModifyPage ${name} order contains an invalid page identity`);
    }
    seen.add(pageId);
  }
  return seen;
}

function withoutPage(order: string[], pageId: string): string[] {
  const result: string[] = [];
  for (const candidate of order) {
    if (candidate !== pageId) {
      result.push(candidate);
    }
  }
  return result;
}

function findIndex(order: string[], pageId: string): number {
  for (let index: number = 0; index < order.length; index++) {
    if (order[index] === pageId) {
      return index;
    }
  }
  return -1;
}

function sameStrings(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}

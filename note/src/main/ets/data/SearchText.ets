export function foldSearchText(text: string): string {
  return text.toLowerCase();
}

export function escapeSearchLike(text: string): string {
  return text.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

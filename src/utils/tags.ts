export function normalizeTag(tag: string): string {
  return tag.replace(/^#/, '').trim().toLowerCase();
}

export function tagHref(tag: string): string {
  return `/tags/${encodeURIComponent(normalizeTag(tag))}/`;
}

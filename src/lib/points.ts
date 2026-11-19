/**
 * Locked T-shirt → points mapping (Phase 0).
 * XS=2, S=8, M=21, L=34, XL=55. Size is source of truth; points denormalize in DB.
 */
export const TICKET_SIZE_POINTS = {
  xs: 2,
  s: 8,
  m: 21,
  l: 34,
  xl: 55,
} as const;

export type TicketSize = keyof typeof TICKET_SIZE_POINTS;

export function ticketSizeToPoints(size: TicketSize | null | undefined): number | null {
  if (!size) return null;
  return TICKET_SIZE_POINTS[size] ?? null;
}

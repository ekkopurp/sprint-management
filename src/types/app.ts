import type {
  SprintStatus,
  TicketPriority,
  TicketSize,
  TicketType,
  WorkspaceRole,
} from "@/types/database";

/** View-model stubs for later phases — keep thin in Phase 0. */
export type WorkspaceSummary = {
  id: string;
  name: string;
  slug: string;
  role: WorkspaceRole;
};

export type TicketListItem = {
  id: string;
  number: number;
  title: string;
  ticket_type: TicketType;
  priority: TicketPriority;
  size: TicketSize | null;
  points: number | null;
  stage_id: string;
  sprint_id: string | null;
  epic_id: string | null;
};

export type SprintSummary = {
  id: string;
  name: string;
  status: SprintStatus;
  starts_on: string | null;
  ends_on: string | null;
};

/** Locked default kanban stage names (seeded on workspace create). */
export const DEFAULT_KANBAN_STAGES = [
  { position: 1, name: "To Do", is_done: false },
  { position: 2, name: "In Progress", is_done: false },
  { position: 3, name: "Staging/QA", is_done: false },
  { position: 4, name: "PR for Review", is_done: false },
  { position: 5, name: "Waiting for Deploy", is_done: false },
  { position: 6, name: "Deployed (PO to Check)", is_done: false },
  { position: 7, name: "Done", is_done: true },
] as const;

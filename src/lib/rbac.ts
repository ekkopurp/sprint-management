/** Workspace RBAC helpers (app-layer mirror of RLS). Comments: view+ can post. */

export type WorkspaceRole = "admin" | "edit" | "view";

const ROLE_RANK: Record<WorkspaceRole, number> = {
  view: 1,
  edit: 2,
  admin: 3,
};

export function roleAtLeast(
  role: WorkspaceRole | null | undefined,
  minimum: WorkspaceRole,
): boolean {
  if (!role) return false;
  return ROLE_RANK[role] >= ROLE_RANK[minimum];
}

export function canEditTickets(role: WorkspaceRole | null | undefined): boolean {
  return roleAtLeast(role, "edit");
}

/** Locked: view role can post comments. */
export function canComment(role: WorkspaceRole | null | undefined): boolean {
  return roleAtLeast(role, "view");
}

export function canAdmin(role: WorkspaceRole | null | undefined): boolean {
  return roleAtLeast(role, "admin");
}

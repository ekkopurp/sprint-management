/**
 * Hand-written Phase 0 types mirroring supabase/migrations.
 * Replace with `supabase gen types typescript` once the project is linked.
 */

export type WorkspaceRole = "admin" | "edit" | "view";
export type InviteStatus = "pending" | "accepted" | "revoked" | "expired";
export type TicketPriority = "high" | "medium" | "low";
export type TicketType = "story" | "bug" | "task" | "spike" | "integration";
export type TicketSize = "xs" | "s" | "m" | "l" | "xl";
export type SprintStatus = "planned" | "active" | "completed";

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          display_name: string | null;
          avatar_url: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          display_name?: string | null;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["profiles"]["Insert"]>;
      };
      workspaces: {
        Row: {
          id: string;
          name: string;
          slug: string;
          created_by: string | null;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          slug: string;
          created_by?: string | null;
          archived_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["workspaces"]["Insert"]>;
      };
      workspace_members: {
        Row: {
          id: string;
          workspace_id: string;
          user_id: string;
          role: WorkspaceRole;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          user_id: string;
          role?: WorkspaceRole;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["workspace_members"]["Insert"]
        >;
      };
      invites: {
        Row: {
          id: string;
          workspace_id: string;
          email: string;
          role: WorkspaceRole;
          token_hash: string;
          status: InviteStatus;
          invited_by: string | null;
          expires_at: string;
          accepted_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          email: string;
          role?: WorkspaceRole;
          token_hash: string;
          status?: InviteStatus;
          invited_by?: string | null;
          expires_at: string;
          accepted_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["invites"]["Insert"]>;
      };
      kanban_stages: {
        Row: {
          id: string;
          workspace_id: string;
          name: string;
          position: number;
          is_done: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          name: string;
          position: number;
          is_done?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["kanban_stages"]["Insert"]>;
      };
      sprints: {
        Row: {
          id: string;
          workspace_id: string;
          name: string;
          goal: string | null;
          status: SprintStatus;
          starts_on: string | null;
          ends_on: string | null;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          name: string;
          goal?: string | null;
          status?: SprintStatus;
          starts_on?: string | null;
          ends_on?: string | null;
          archived_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["sprints"]["Insert"]>;
      };
      epics: {
        Row: {
          id: string;
          workspace_id: string;
          title: string;
          description: string | null;
          owner_id: string | null;
          target_date: string | null;
          color: string | null;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          title: string;
          description?: string | null;
          owner_id?: string | null;
          target_date?: string | null;
          color?: string | null;
          archived_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["epics"]["Insert"]>;
      };
      tickets: {
        Row: {
          id: string;
          workspace_id: string;
          number: number;
          title: string;
          description: string | null;
          ticket_type: TicketType;
          priority: TicketPriority;
          size: TicketSize | null;
          points: number | null;
          stage_id: string;
          sprint_id: string | null;
          epic_id: string | null;
          assignee_id: string | null;
          reporter_id: string | null;
          position: number;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          number?: number;
          title: string;
          description?: string | null;
          ticket_type?: TicketType;
          priority?: TicketPriority;
          size?: TicketSize | null;
          points?: number | null;
          stage_id: string;
          sprint_id?: string | null;
          epic_id?: string | null;
          assignee_id?: string | null;
          reporter_id?: string | null;
          position?: number;
          archived_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["tickets"]["Insert"]>;
      };
      tags: {
        Row: {
          id: string;
          workspace_id: string;
          name: string;
          color: string | null;
          archived_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          name: string;
          color?: string | null;
          archived_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["tags"]["Insert"]>;
      };
      ticket_tags: {
        Row: { ticket_id: string; tag_id: string };
        Insert: { ticket_id: string; tag_id: string };
        Update: Partial<Database["public"]["Tables"]["ticket_tags"]["Insert"]>;
      };
      comments: {
        Row: {
          id: string;
          workspace_id: string;
          ticket_id: string;
          author_id: string;
          body: string;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          workspace_id: string;
          ticket_id: string;
          author_id: string;
          body: string;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: Partial<Database["public"]["Tables"]["comments"]["Insert"]>;
      };
      comment_mentions: {
        Row: { comment_id: string; mentioned_user_id: string };
        Insert: { comment_id: string; mentioned_user_id: string };
        Update: Partial<
          Database["public"]["Tables"]["comment_mentions"]["Insert"]
        >;
      };
      workspace_links: {
        Row: {
          id: string;
          source_workspace_id: string;
          target_workspace_id: string;
          link_type: string;
          created_by: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          source_workspace_id: string;
          target_workspace_id: string;
          link_type: string;
          created_by?: string | null;
          created_at?: string;
        };
        Update: Partial<
          Database["public"]["Tables"]["workspace_links"]["Insert"]
        >;
      };
      workspace_ticket_counters: {
        Row: { workspace_id: string; last_number: number };
        Insert: { workspace_id: string; last_number?: number };
        Update: Partial<
          Database["public"]["Tables"]["workspace_ticket_counters"]["Insert"]
        >;
      };
    };
    Enums: {
      workspace_role: WorkspaceRole;
      invite_status: InviteStatus;
      ticket_priority: TicketPriority;
      ticket_type: TicketType;
      ticket_size: TicketSize;
      sprint_status: SprintStatus;
    };
  };
}

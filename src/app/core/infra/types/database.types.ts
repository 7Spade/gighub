/**
 * Supabase Database Type Definitions
 *
 * Type definitions aligned with database schema:
 * 20251129000001_create_multi_tenant_saas_schema.sql
 *
 * @module core/infra/types
 */

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

// ============================================================================
// Database Enums (aligned with SQL schema)
// These types match the database enum values exactly.
// Use Db* prefix to avoid conflicts with runtime enums in account/index.ts
// ============================================================================

export type DbAccountType = 'user' | 'org' | 'bot';
export type DbAccountStatus = 'active' | 'inactive' | 'suspended' | 'deleted';
export type DbOrganizationRole = 'owner' | 'admin' | 'member';
export type DbTeamRole = 'leader' | 'member';
export type DbBlueprintRole = 'viewer' | 'contributor' | 'maintainer';
export type DbBlueprintTeamAccess = 'read' | 'write' | 'admin';
export type DbModuleType = 'tasks' | 'diary' | 'dashboard' | 'bot_workflow' | 'files' | 'todos' | 'checklists' | 'issues';
export type DbTaskStatus = 'pending' | 'in_progress' | 'in_review' | 'completed' | 'cancelled' | 'blocked';
export type DbTaskPriority = 'lowest' | 'low' | 'medium' | 'high' | 'highest';
export type DbIssueSeverity = 'low' | 'medium' | 'high' | 'critical';
export type DbIssueStatus = 'new' | 'assigned' | 'in_progress' | 'pending_confirm' | 'resolved' | 'closed' | 'reopened';
export type DbAcceptanceResult = 'pending' | 'passed' | 'failed' | 'conditional';
export type DbWeatherType = 'sunny' | 'cloudy' | 'rainy' | 'stormy' | 'snowy' | 'foggy';

// ============================================================================
// Database Schema Interface
// ============================================================================

export interface Database {
  public: {
    Tables: {
      // Index signature to allow string-based table access (for generic repositories)
      [key: string]: {
        Row: Record<string, unknown>;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Array<{
          foreignKeyName: string;
          columns: string[];
          isOneToOne: boolean;
          referencedRelation: string;
          referencedColumns: string[];
        }>;
      };
      // Foundation Layer: Accounts
      accounts: {
        Row: {
          id: string;
          auth_user_id: string | null;
          type: DbAccountType;
          status: DbAccountStatus;
          name: string;
          email: string | null;
          avatar_url: string | null;
          metadata: Json;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          auth_user_id?: string | null;
          type?: DbAccountType;
          status?: DbAccountStatus;
          name: string;
          email?: string | null;
          avatar_url?: string | null;
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          auth_user_id?: string | null;
          type?: DbAccountType;
          status?: DbAccountStatus;
          name?: string;
          email?: string | null;
          avatar_url?: string | null;
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [];
      };
      // Foundation Layer: Organizations
      organizations: {
        Row: {
          id: string;
          account_id: string;
          name: string;
          slug: string;
          description: string | null;
          logo_url: string | null;
          metadata: Json;
          created_by: string | null;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          account_id: string;
          name: string;
          slug: string;
          description?: string | null;
          logo_url?: string | null;
          metadata?: Json;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          account_id?: string;
          name?: string;
          slug?: string;
          description?: string | null;
          logo_url?: string | null;
          metadata?: Json;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'organizations_account_id_fkey';
            columns: ['account_id'];
            isOneToOne: true;
            referencedRelation: 'accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      // Foundation Layer: Organization Members
      organization_members: {
        Row: {
          id: string;
          organization_id: string;
          account_id: string;
          role: DbOrganizationRole;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          organization_id: string;
          account_id: string;
          role?: DbOrganizationRole;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          organization_id?: string;
          account_id?: string;
          role?: DbOrganizationRole;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'organization_members_organization_id_fkey';
            columns: ['organization_id'];
            isOneToOne: false;
            referencedRelation: 'organizations';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'organization_members_account_id_fkey';
            columns: ['account_id'];
            isOneToOne: false;
            referencedRelation: 'accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      // Foundation Layer: Teams
      teams: {
        Row: {
          id: string;
          organization_id: string;
          name: string;
          description: string | null;
          metadata: Json;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          organization_id: string;
          name: string;
          description?: string | null;
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          organization_id?: string;
          name?: string;
          description?: string | null;
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'teams_organization_id_fkey';
            columns: ['organization_id'];
            isOneToOne: false;
            referencedRelation: 'organizations';
            referencedColumns: ['id'];
          }
        ];
      };
      // Foundation Layer: Team Members
      team_members: {
        Row: {
          id: string;
          team_id: string;
          account_id: string;
          role: DbTeamRole;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          team_id: string;
          account_id: string;
          role?: DbTeamRole;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          team_id?: string;
          account_id?: string;
          role?: DbTeamRole;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'team_members_team_id_fkey';
            columns: ['team_id'];
            isOneToOne: false;
            referencedRelation: 'teams';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'team_members_account_id_fkey';
            columns: ['account_id'];
            isOneToOne: false;
            referencedRelation: 'accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      // Container Layer: Blueprints
      blueprints: {
        Row: {
          id: string;
          owner_id: string;
          name: string;
          slug: string;
          description: string | null;
          cover_url: string | null;
          is_public: boolean;
          status: DbAccountStatus;
          enabled_modules: DbModuleType[];
          metadata: Json;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          owner_id: string;
          name: string;
          slug: string;
          description?: string | null;
          cover_url?: string | null;
          is_public?: boolean;
          status?: DbAccountStatus;
          enabled_modules?: DbModuleType[];
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          owner_id?: string;
          name?: string;
          slug?: string;
          description?: string | null;
          cover_url?: string | null;
          is_public?: boolean;
          status?: DbAccountStatus;
          enabled_modules?: DbModuleType[];
          metadata?: Json;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'blueprints_owner_id_fkey';
            columns: ['owner_id'];
            isOneToOne: false;
            referencedRelation: 'accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      // Container Layer: Blueprint Members
      blueprint_members: {
        Row: {
          id: string;
          blueprint_id: string;
          account_id: string;
          role: DbBlueprintRole;
          is_external: boolean;
          invited_by: string | null;
          invited_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          blueprint_id: string;
          account_id: string;
          role?: DbBlueprintRole;
          is_external?: boolean;
          invited_by?: string | null;
          invited_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          blueprint_id?: string;
          account_id?: string;
          role?: DbBlueprintRole;
          is_external?: boolean;
          invited_by?: string | null;
          invited_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'blueprint_members_blueprint_id_fkey';
            columns: ['blueprint_id'];
            isOneToOne: false;
            referencedRelation: 'blueprints';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'blueprint_members_account_id_fkey';
            columns: ['account_id'];
            isOneToOne: false;
            referencedRelation: 'accounts';
            referencedColumns: ['id'];
          }
        ];
      };
      // Business Layer: Tasks
      tasks: {
        Row: {
          id: string;
          blueprint_id: string;
          parent_id: string | null;
          title: string;
          description: string | null;
          status: DbTaskStatus;
          priority: DbTaskPriority;
          assignee_id: string | null;
          reviewer_id: string | null;
          due_date: string | null;
          start_date: string | null;
          completion_rate: number;
          sort_order: number;
          metadata: Json;
          created_by: string | null;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          blueprint_id: string;
          parent_id?: string | null;
          title: string;
          description?: string | null;
          status?: DbTaskStatus;
          priority?: DbTaskPriority;
          assignee_id?: string | null;
          reviewer_id?: string | null;
          due_date?: string | null;
          start_date?: string | null;
          completion_rate?: number;
          sort_order?: number;
          metadata?: Json;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          blueprint_id?: string;
          parent_id?: string | null;
          title?: string;
          description?: string | null;
          status?: DbTaskStatus;
          priority?: DbTaskPriority;
          assignee_id?: string | null;
          reviewer_id?: string | null;
          due_date?: string | null;
          start_date?: string | null;
          completion_rate?: number;
          sort_order?: number;
          metadata?: Json;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'tasks_blueprint_id_fkey';
            columns: ['blueprint_id'];
            isOneToOne: false;
            referencedRelation: 'blueprints';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'tasks_parent_id_fkey';
            columns: ['parent_id'];
            isOneToOne: false;
            referencedRelation: 'tasks';
            referencedColumns: ['id'];
          }
        ];
      };
      // Business Layer: Diaries
      diaries: {
        Row: {
          id: string;
          blueprint_id: string;
          work_date: string;
          weather: DbWeatherType | null;
          temperature_min: number | null;
          temperature_max: number | null;
          work_hours: number | null;
          worker_count: number | null;
          summary: string | null;
          notes: string | null;
          status: DbAccountStatus;
          created_by: string | null;
          approved_by: string | null;
          approved_at: string | null;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          blueprint_id: string;
          work_date: string;
          weather?: DbWeatherType | null;
          temperature_min?: number | null;
          temperature_max?: number | null;
          work_hours?: number | null;
          worker_count?: number | null;
          summary?: string | null;
          notes?: string | null;
          status?: DbAccountStatus;
          created_by?: string | null;
          approved_by?: string | null;
          approved_at?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          blueprint_id?: string;
          work_date?: string;
          weather?: DbWeatherType | null;
          temperature_min?: number | null;
          temperature_max?: number | null;
          work_hours?: number | null;
          worker_count?: number | null;
          summary?: string | null;
          notes?: string | null;
          status?: DbAccountStatus;
          created_by?: string | null;
          approved_by?: string | null;
          approved_at?: string | null;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'diaries_blueprint_id_fkey';
            columns: ['blueprint_id'];
            isOneToOne: false;
            referencedRelation: 'blueprints';
            referencedColumns: ['id'];
          }
        ];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      account_type: DbAccountType;
      account_status: DbAccountStatus;
      organization_role: DbOrganizationRole;
      team_role: DbTeamRole;
      blueprint_role: DbBlueprintRole;
      blueprint_team_access: DbBlueprintTeamAccess;
      module_type: DbModuleType;
      task_status: DbTaskStatus;
      task_priority: DbTaskPriority;
      issue_severity: DbIssueSeverity;
      issue_status: DbIssueStatus;
      acceptance_result: DbAcceptanceResult;
      weather_type: DbWeatherType;
    };
    CompositeTypes: Record<string, never>;
  };
}

/**
 * Helper types for working with database tables
 */
export type Tables<
  PublicTableNameOrOptions extends keyof (Database['public']['Tables'] & Database['public']['Views']) | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions['schema']]['Tables'] & Database[PublicTableNameOrOptions['schema']]['Views'])
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions['schema']]['Tables'] & Database[PublicTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (Database['public']['Tables'] & Database['public']['Views'])
    ? (Database['public']['Tables'] & Database['public']['Views'])[PublicTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  PublicTableNameOrOptions extends keyof Database['public']['Tables'] | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions['schema']]['Tables']
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof Database['public']['Tables']
    ? Database['public']['Tables'][PublicTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  PublicTableNameOrOptions extends keyof Database['public']['Tables'] | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions['schema']]['Tables']
    : never = never
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof Database['public']['Tables']
    ? Database['public']['Tables'][PublicTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  PublicEnumNameOrOptions extends keyof Database['public']['Enums'] | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions['schema']]['Enums']
    : never = never
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions['schema']]['Enums'][EnumName]
  : PublicEnumNameOrOptions extends keyof Database['public']['Enums']
    ? Database['public']['Enums'][PublicEnumNameOrOptions]
    : never;

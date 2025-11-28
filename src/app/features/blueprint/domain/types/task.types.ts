/**
 * Task Types
 *
 * Type definitions for Task Module (任務模組)
 * Supporting unlimited depth hierarchy with tree structure
 * Following vertical slice architecture and enterprise guidelines
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/domain/types/task.types
 */

/**
 * Task status (狀態) - Per SETC-05
 */
export type TaskStatus =
  | 'pending' // 待處理
  | 'in_progress' // 進行中
  | 'in_review' // 審核中
  | 'completed' // 已完成
  | 'cancelled' // 已取消
  | 'blocked'; // 已阻塞

/**
 * Task priority - Per SETC-05
 */
export type TaskPriority = 'lowest' | 'low' | 'medium' | 'high' | 'highest';

/**
 * Task type - Per SETC-05
 */
export type TaskType = 'task' | 'milestone' | 'bug' | 'feature' | 'improvement';

/**
 * Assignee type (被指派者類型)
 */
export type AssigneeType = 'user' | 'team' | 'organization';

/**
 * Task entity with unlimited tree depth
 * Aligned with SETC-05 database schema
 */
export interface Task {
  // Identity
  id: string;
  blueprintId: string;

  // Tree structure (無限子層)
  parentId: string | null; // null for root tasks (L0)
  sortOrder: number; // Sibling ordering (0-based)

  // Basic info
  name: string; // 任務名稱
  description?: string;
  status: TaskStatus; // 狀態
  priority: TaskPriority;
  taskType: TaskType;

  // Progress tracking (進度)
  progress: number; // 進度百分比 (0-100)
  weight: number; // 權重 for parent calculation

  // Scheduling
  startDate?: string; // ISO date string
  dueDate?: string; // ISO date string

  // Assignment (被指派者)
  assigneeId: string | null; // 執行者
  reviewerId: string | null; // 監工

  // Location & Categorization
  area?: string; // 區域
  tags: string[]; // 標籤

  // Audit
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  completedAt?: string;
  deletedAt?: string;
}

/**
 * Task insert type (for creation)
 */
export interface TaskInsert {
  blueprintId: string;
  parentId?: string | null;
  sortOrder?: number;
  name: string;
  description?: string;
  status?: TaskStatus;
  priority?: TaskPriority;
  taskType?: TaskType;
  progress?: number;
  weight?: number;
  startDate?: string;
  dueDate?: string;
  assigneeId?: string | null;
  reviewerId?: string | null;
  area?: string;
  tags?: string[];
  createdBy: string;
}

/**
 * Task update type (for modifications)
 */
export interface TaskUpdate {
  name?: string;
  description?: string;
  status?: TaskStatus;
  priority?: TaskPriority;
  taskType?: TaskType;
  progress?: number;
  weight?: number;
  startDate?: string;
  dueDate?: string;
  assigneeId?: string | null;
  reviewerId?: string | null;
  area?: string;
  tags?: string[];
  sortOrder?: number;
  parentId?: string | null;
  completedAt?: string;
}

/**
 * Task tree node for UI display
 */
export interface TaskTreeNode {
  key: string; // task.id
  title: string; // task.name
  level: string; // 'L0', 'L1', 'L2', 'L3'...
  isLeaf: boolean; // No children
  expanded: boolean;
  children: TaskTreeNode[];

  // Task data
  task: Task;

  // Display metadata
  icon: string; // Icon based on status
  disabled: boolean;
}

/**
 * Task assignment record
 */
export interface TaskAssignment {
  id: string;
  taskId: string;
  assigneeId: string;
  assigneeType: AssigneeType;
  assignedAt: Date;
  assignedBy: string;
}

/**
 * Type guards - Updated for SETC-05
 */
export function isTaskStatus(value: unknown): value is TaskStatus {
  return typeof value === 'string' && ['pending', 'in_progress', 'in_review', 'completed', 'cancelled', 'blocked'].includes(value);
}

export function isTaskPriority(value: unknown): value is TaskPriority {
  return typeof value === 'string' && ['lowest', 'low', 'medium', 'high', 'highest'].includes(value);
}

export function isTaskType(value: unknown): value is TaskType {
  return typeof value === 'string' && ['task', 'milestone', 'bug', 'feature', 'improvement'].includes(value);
}

export function isAssigneeType(value: unknown): value is AssigneeType {
  return typeof value === 'string' && ['user', 'team', 'organization'].includes(value);
}

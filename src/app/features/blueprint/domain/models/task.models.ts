/**
 * Task Models
 *
 * Business models for Task Module (任務模組)
 * Following vertical slice architecture
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/domain/models/task.models
 */

import { Task, TaskStatus, TaskPriority, TaskType } from '../types';

/**
 * Task Model (re-export from types with business context)
 */
export type TaskModel = Task;

/**
 * Task level helper (L0, L1, L2, L3...)
 */
export type TaskLevel = `L${number}`;

/**
 * Task summary for list display
 */
export interface TaskSummary {
  id: string;
  name: string;
  status: TaskStatus;
  priority: TaskPriority;
  taskType: TaskType;
  progress: number;
  assigneeId: string | null;
  reviewerId: string | null;
  area?: string;
  tags: string[];
  dueDate?: string;
}

/**
 * Task creation request - Per SETC-05
 */
export interface CreateTaskRequest {
  blueprintId: string;
  parentId?: string | null;
  sortOrder?: number;
  name: string;
  description?: string;
  priority?: TaskPriority;
  taskType?: TaskType;
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
 * Task update request - Per SETC-05
 */
export interface UpdateTaskRequest {
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
 * Task move request (change parent or position)
 */
export interface MoveTaskRequest {
  taskId: string;
  newParentId?: string | null;
  newSortOrder: number;
}

/**
 * Task statistics for blueprint - Per SETC-05
 */
export interface TaskStatistics {
  totalCount: number;
  pendingCount: number;
  inProgressCount: number;
  inReviewCount: number;
  completedCount: number;
  cancelledCount: number;
  blockedCount: number;
  overallProgress: number;
}

/**
 * Task filter options
 */
export interface TaskFilterOptions {
  status?: TaskStatus;
  priority?: TaskPriority;
  taskType?: TaskType;
  assigneeId?: string;
  reviewerId?: string;
  area?: string;
  tags?: string[];
  searchTerm?: string;
}

/**
 * Task view mode
 */
export type TaskViewMode = 'tree' | 'table';

/**
 * Task assignment request
 */
export interface AssignTaskRequest {
  taskId: string;
  assigneeId: string | null;
  reviewerId?: string | null;
}

/**
 * Bulk task operation request
 */
export interface BulkTaskOperationRequest {
  taskIds: string[];
  operation: 'complete' | 'cancel' | 'delete' | 'assign' | 'submit_review';
  payload?: unknown; // Operation-specific data
}

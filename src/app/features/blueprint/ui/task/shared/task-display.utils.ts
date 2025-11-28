/**
 * Task Display Utilities
 *
 * Utility functions for task display formatting
 * Shared between tree and table views
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/ui/task/shared/task-display.utils
 */

import { TaskStatus, TaskPriority, TaskType } from '../../../domain';

/**
 * Status badge color mapping - Per SETC-05
 */
const STATUS_COLORS: Record<TaskStatus, string> = {
  pending: 'default',
  in_progress: 'processing',
  in_review: 'warning',
  completed: 'success',
  cancelled: 'error',
  blocked: 'magenta'
};

/**
 * Status display text mapping (Traditional Chinese) - Per SETC-05
 */
const STATUS_TEXTS: Record<TaskStatus, string> = {
  pending: '待處理',
  in_progress: '進行中',
  in_review: '審核中',
  completed: '已完成',
  cancelled: '已取消',
  blocked: '已阻塞'
};

/**
 * Priority color mapping - Per SETC-05
 */
const PRIORITY_COLORS: Record<TaskPriority, string> = {
  lowest: 'default',
  low: 'blue',
  medium: 'warning',
  high: 'orange',
  highest: 'error'
};

/**
 * Priority display text mapping - Per SETC-05
 */
const PRIORITY_TEXTS: Record<TaskPriority, string> = {
  lowest: '最低',
  low: '低',
  medium: '中',
  high: '高',
  highest: '最高'
};

/**
 * Task type color mapping - Per SETC-05
 */
const TASK_TYPE_COLORS: Record<TaskType, string> = {
  task: 'blue',
  milestone: 'gold',
  bug: 'red',
  feature: 'green',
  improvement: 'cyan'
};

/**
 * Task type text mapping - Per SETC-05
 */
const TASK_TYPE_TEXTS: Record<TaskType, string> = {
  task: '任務',
  milestone: '里程碑',
  bug: '缺陷',
  feature: '功能',
  improvement: '改進'
};

/**
 * Get status badge color for ng-zorro badge
 */
export function getStatusColor(status: TaskStatus): string {
  return STATUS_COLORS[status] ?? 'default';
}

/**
 * Get status display text
 */
export function getStatusText(status: TaskStatus): string {
  return STATUS_TEXTS[status] ?? status;
}

/**
 * Get priority tag color
 */
export function getPriorityColor(priority: TaskPriority): string {
  return PRIORITY_COLORS[priority] ?? 'default';
}

/**
 * Get priority display text
 */
export function getPriorityText(priority: TaskPriority): string {
  return PRIORITY_TEXTS[priority] ?? priority;
}

/**
 * Get task type tag color
 */
export function getTaskTypeColor(taskType: TaskType): string {
  return TASK_TYPE_COLORS[taskType] ?? 'default';
}

/**
 * Get task type display text
 */
export function getTaskTypeText(taskType: TaskType): string {
  return TASK_TYPE_TEXTS[taskType] ?? taskType;
}

/**
 * Format progress display
 */
export function formatProgress(completed: number, total: number): string {
  if (total === 0) return '-';
  return `${completed} / ${total}`;
}

/**
 * Calculate progress percentage
 */
export function calculateProgress(completed: number, total: number): number {
  if (total === 0) return 0;
  return Math.round((completed / total) * 100);
}

/**
 * Get progress bar status color
 */
export function getProgressStatus(progress: number): 'success' | 'normal' | 'exception' | 'active' {
  if (progress >= 100) return 'success';
  if (progress > 0) return 'active';
  return 'normal';
}

/**
 * Format assignee display
 * Returns initials for avatar display
 */
export function formatAssigneeInitials(assigneeId: string): string {
  return assigneeId.slice(0, 2).toUpperCase();
}

/**
 * Get tree node icon based on status and expandable state
 */
export function getNodeIcon(status: TaskStatus, expandable: boolean): string {
  if (status === 'completed') return 'check-circle';
  if (status === 'cancelled') return 'close-circle';
  if (status === 'blocked') return 'stop';
  if (status === 'in_progress') return 'loading';
  if (status === 'in_review') return 'eye';
  if (expandable) return 'folder';
  return 'file';
}

/**
 * Get icon theme based on status
 */
export function getIconTheme(status: TaskStatus): 'outline' | 'fill' | 'twotone' {
  return status === 'completed' || status === 'cancelled' || status === 'blocked' ? 'fill' : 'outline';
}

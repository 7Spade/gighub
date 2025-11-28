/**
 * Task Enums
 *
 * Enum definitions for Task business logic
 * Following vertical slice architecture
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/domain/enums/task.enums
 */

/**
 * Task status enum for business logic - Per SETC-05
 */
export enum TaskStatusEnum {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  IN_REVIEW = 'in_review',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  BLOCKED = 'blocked'
}

/**
 * Task priority enum for business logic - Per SETC-05
 */
export enum TaskPriorityEnum {
  LOWEST = 'lowest',
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  HIGHEST = 'highest'
}

/**
 * Task type enum for business logic - Per SETC-05
 */
export enum TaskTypeEnum {
  TASK = 'task',
  MILESTONE = 'milestone',
  BUG = 'bug',
  FEATURE = 'feature',
  IMPROVEMENT = 'improvement'
}

/**
 * Assignee type enum for business logic
 */
export enum AssigneeTypeEnum {
  USER = 'user',
  TEAM = 'team',
  ORGANIZATION = 'organization'
}

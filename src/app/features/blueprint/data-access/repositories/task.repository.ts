/**
 * Task Repository
 *
 * Repository for Task data access layer
 * Supporting unlimited depth tree operations
 * Following vertical slice architecture
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/data-access/repositories/task.repository
 */

import { Injectable } from '@angular/core';
import { BaseRepository, QueryOptions } from '@core';
import { Observable } from 'rxjs';

import { Task, TaskInsert, TaskUpdate } from '../../domain';

/**
 * Task Repository
 *
 * Handles data access for tasks with tree structure support
 */
@Injectable({ providedIn: 'root' })
export class TaskRepository extends BaseRepository<Task, TaskInsert, TaskUpdate> {
  protected tableName = 'tasks';

  /**
   * Find tasks by blueprint
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of tasks ordered by sortOrder
   */
  findByBlueprint(blueprintId: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId
      },
      order: {
        column: 'sort_order',
        ascending: true
      }
    });
  }

  /**
   * Find tasks by parent
   *
   * @param {string} parentId - Parent task ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of child tasks
   */
  findByParent(parentId: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        parentId
      },
      order: {
        column: 'sort_order',
        ascending: true
      }
    });
  }

  /**
   * Find root tasks (L0)
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of root tasks
   */
  findRootTasks(blueprintId: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        parentId: null
      },
      order: {
        column: 'sort_order',
        ascending: true
      }
    });
  }

  /**
   * Find tasks by status
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {string} status - Task status
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of tasks with specified status
   */
  findByStatus(blueprintId: string, status: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        status
      }
    });
  }

  /**
   * Find tasks by assignee
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {string} assigneeId - Assignee ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of assigned tasks
   */
  findByAssignee(blueprintId: string, assigneeId: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        assigneeId
      }
    });
  }

  /**
   * Find tasks by reviewer
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {string} reviewerId - Reviewer ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of tasks to review
   */
  findByReviewer(blueprintId: string, reviewerId: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        reviewerId
      }
    });
  }

  /**
   * Find tasks by area
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {string} area - Area name
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of tasks in specified area
   */
  findByArea(blueprintId: string, area: string, options?: QueryOptions): Observable<Task[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        area
      }
    });
  }

  /**
   * Find overdue tasks
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Task[]>} Array of overdue tasks
   */
  findOverdue(blueprintId: string, options?: QueryOptions): Observable<Task[]> {
    const today = new Date().toISOString().split('T')[0];
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId,
        'due_date.lt': today,
        'status.neq': 'completed'
      }
    });
  }
}

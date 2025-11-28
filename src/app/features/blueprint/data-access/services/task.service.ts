/**
 * Task Service
 *
 * Business logic for Task Module management
 * Following vertical slice architecture
 * Aligned with SETC-05 specification
 *
 * Uses Angular Signals for reactive state management
 * Supports unlimited depth tree structure
 *
 * @module features/blueprint/data-access/services/task.service
 */

import { Injectable, inject, signal, computed } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { TaskModel, CreateTaskRequest, UpdateTaskRequest, TaskStatistics, TaskViewMode, TaskStatusEnum } from '../../domain';
import { TaskRepository } from '../repositories';

/**
 * Task Service
 *
 * Manages task state and business logic with Signals
 * Supports tree operations for unlimited depth hierarchy
 */
@Injectable({ providedIn: 'root' })
export class TaskService {
  private readonly taskRepo = inject(TaskRepository);

  // State management with Signals
  private tasksState = signal<TaskModel[]>([]);
  private selectedTaskState = signal<TaskModel | null>(null);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);
  private viewModeState = signal<TaskViewMode>('tree');

  // Expose ReadonlySignal to components
  readonly tasks = this.tasksState.asReadonly();
  readonly selectedTask = this.selectedTaskState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();
  readonly viewMode = this.viewModeState.asReadonly();

  // Computed signals for derived state - Per SETC-05 status values
  readonly pendingTasks = computed(() => this.tasks().filter(t => t.status === TaskStatusEnum.PENDING));

  readonly inProgressTasks = computed(() => this.tasks().filter(t => t.status === TaskStatusEnum.IN_PROGRESS));

  readonly completedTasks = computed(() => this.tasks().filter(t => t.status === TaskStatusEnum.COMPLETED));

  readonly rootTasks = computed(() => this.tasks().filter(t => t.parentId === null));

  readonly statistics = computed<TaskStatistics>(() => {
    const tasks = this.tasks();

    return {
      totalCount: tasks.length,
      pendingCount: tasks.filter(t => t.status === TaskStatusEnum.PENDING).length,
      inProgressCount: tasks.filter(t => t.status === TaskStatusEnum.IN_PROGRESS).length,
      inReviewCount: tasks.filter(t => t.status === TaskStatusEnum.IN_REVIEW).length,
      completedCount: tasks.filter(t => t.status === TaskStatusEnum.COMPLETED).length,
      cancelledCount: tasks.filter(t => t.status === TaskStatusEnum.CANCELLED).length,
      blockedCount: tasks.filter(t => t.status === TaskStatusEnum.BLOCKED).length,

      // Overall progress
      overallProgress: tasks.length > 0 ? Math.round(tasks.reduce((sum, t) => sum + t.progress, 0) / tasks.length) : 0
    };
  });

  /**
   * Load tasks by blueprint - Per SETC-05
   */
  async loadTasksByBlueprint(blueprintId: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const tasks = await firstValueFrom(this.taskRepo.findByBlueprint(blueprintId));
      this.tasksState.set(tasks);
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : '載入任務失敗');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Get task by ID
   */
  async getTaskById(id: string): Promise<TaskModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const task = await firstValueFrom(this.taskRepo.findById(id));
      if (!task) {
        throw new Error('任務不存在');
      }
      this.selectedTaskState.set(task);
      return task;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : '載入任務失敗');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Create new task
   */
  async createTask(request: CreateTaskRequest): Promise<TaskModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const taskInsert = {
        blueprintId: request.blueprintId,
        parentId: request.parentId || null,
        sortOrder: request.sortOrder || 0,
        name: request.name,
        description: request.description,
        status: 'pending' as const,
        priority: request.priority || ('medium' as const),
        taskType: request.taskType || ('task' as const),
        progress: 0,
        weight: request.weight || 1.0,
        startDate: request.startDate,
        dueDate: request.dueDate,
        assigneeId: request.assigneeId || null,
        reviewerId: request.reviewerId || null,
        area: request.area,
        tags: request.tags || [],
        createdBy: request.createdBy
      };

      const newTask = await firstValueFrom(this.taskRepo.create(taskInsert));

      // Update state
      this.tasksState.update(tasks => [...tasks, newTask]);

      return newTask;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : '建立任務失敗');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Update task
   */
  async updateTask(id: string, request: UpdateTaskRequest): Promise<TaskModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const updatedTask = await firstValueFrom(this.taskRepo.update(id, request));

      // Update state
      this.tasksState.update(tasks => tasks.map(t => (t.id === id ? updatedTask : t)));

      if (this.selectedTask()?.id === id) {
        this.selectedTaskState.set(updatedTask);
      }

      return updatedTask;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : '更新任務失敗');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Delete task (soft delete)
   */
  async deleteTask(id: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      await firstValueFrom(this.taskRepo.delete(id));

      // Update state
      this.tasksState.update(tasks => tasks.filter(t => t.id !== id));

      if (this.selectedTask()?.id === id) {
        this.selectedTaskState.set(null);
      }
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : '刪除任務失敗');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Complete task
   */
  async completeTask(id: string): Promise<TaskModel> {
    return this.updateTask(id, {
      status: TaskStatusEnum.COMPLETED,
      completedAt: new Date().toISOString()
    });
  }

  /**
   * Cancel task
   */
  async cancelTask(id: string): Promise<TaskModel> {
    return this.updateTask(id, { status: TaskStatusEnum.CANCELLED });
  }

  /**
   * Set view mode (tree or table)
   */
  setViewMode(mode: TaskViewMode): void {
    this.viewModeState.set(mode);
  }

  /**
   * Clear error state
   */
  clearError(): void {
    this.errorState.set(null);
  }

  /**
   * Clear selection
   */
  clearSelection(): void {
    this.selectedTaskState.set(null);
  }
}

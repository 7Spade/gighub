/**
 * Todo List Component
 *
 * Container component for todo module
 * Displays list of todo items with filtering and status management
 *
 * @module features/blueprint/ui/todo/todo-list
 */

import { Component, inject, signal, computed, ChangeDetectionStrategy, OnInit } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';

import { TodoStore } from '../../../data-access';
import { TodoViewModel, TodoStatus } from '../../../domain';

/**
 * Todo List Component
 *
 * Container managing todo list display, filtering and status changes
 */
@Component({
  selector: 'app-todo-list',
  standalone: true,
  imports: [SHARED_IMPORTS],
  templateUrl: './todo-list.component.html',
  styleUrl: './todo-list.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TodoListComponent implements OnInit {
  private readonly todoStore = inject(TodoStore);

  /** Store state */
  readonly todos = this.todoStore.todos;
  readonly todoViewModels = this.todoStore.todoViewModels;
  readonly loading = this.todoStore.loading;
  readonly error = this.todoStore.error;
  readonly statistics = this.todoStore.statistics;

  /** Local state */
  readonly searchTerm = signal<string>('');
  readonly statusFilter = signal<TodoStatus | 'all'>('all');
  readonly showCompleted = signal<boolean>(false);

  /** Status options for filter */
  readonly statusOptions: Array<{ value: TodoStatus | 'all'; label: string }> = [
    { value: 'all', label: '全部' },
    { value: 'open', label: '待處理' },
    { value: 'in_progress', label: '進行中' },
    { value: 'done', label: '已完成' },
    { value: 'cancelled', label: '已取消' }
  ];

  /** Filtered todos based on search and status */
  readonly filteredTodos = computed(() => {
    const allTodos = this.todoViewModels();
    const term = this.searchTerm().toLowerCase();
    const status = this.statusFilter();
    const includeCompleted = this.showCompleted();

    let filtered = allTodos;

    // Filter by status
    if (status !== 'all') {
      filtered = filtered.filter(t => t.status === status);
    } else if (!includeCompleted) {
      filtered = filtered.filter(t => t.status !== 'done' && t.status !== 'cancelled');
    }

    // Filter by search term
    if (term) {
      filtered = filtered.filter(
        t =>
          t.title.toLowerCase().includes(term) ||
          t.description?.toLowerCase().includes(term) ||
          t.tags.some(tag => tag.toLowerCase().includes(term))
      );
    }

    return filtered;
  });

  // eslint-disable-next-line @angular-eslint/no-empty-lifecycle-method
  ngOnInit(): void {
    // Load initial data - would need workspaceId from context
    // this.todoStore.loadWorkspaceTodos(workspaceId);
  }

  /** Handle search input */
  onSearch(term: string): void {
    this.searchTerm.set(term);
  }

  /** Handle status filter change */
  onStatusFilterChange(status: TodoStatus | 'all'): void {
    this.statusFilter.set(status);
  }

  /** Toggle show completed */
  toggleShowCompleted(): void {
    this.showCompleted.update(v => !v);
  }

  /** Handle create todo */
  onCreateTodo(): void {
    // TODO: Open todo creation dialog
    console.log('Create todo clicked');
  }

  /** Handle toggle status (checkbox) */
  async onToggleComplete(todo: TodoViewModel): Promise<void> {
    try {
      if (todo.status === 'done') {
        await this.todoStore.reopenTodo(todo.id);
      } else {
        await this.todoStore.markAsDone(todo.id);
      }
    } catch (error) {
      console.error('Failed to toggle todo status:', error);
    }
  }

  /** Handle view todo */
  onViewTodo(todo: TodoViewModel): void {
    // TODO: Navigate to todo detail or open dialog
    console.log('View todo:', todo.id);
  }

  /** Handle edit todo */
  onEditTodo(todo: TodoViewModel): void {
    // TODO: Open todo edit dialog
    console.log('Edit todo:', todo.id);
  }

  /** Handle delete todo */
  onDeleteTodo(todo: TodoViewModel): void {
    // TODO: Show delete confirmation dialog
    console.log('Delete todo:', todo.id);
  }

  /** Get priority color */
  getPriorityColor(priority: string): string {
    const colors: Record<string, string> = {
      low: 'default',
      normal: 'blue',
      high: 'orange',
      urgent: 'red'
    };
    return colors[priority] || 'default';
  }

  /** Get status color */
  getStatusColor(status: string): string {
    const colors: Record<string, string> = {
      open: 'blue',
      in_progress: 'orange',
      done: 'green',
      cancelled: 'default'
    };
    return colors[status] || 'default';
  }

  /** Track by function for ngFor */
  trackByTodo(_index: number, todo: TodoViewModel): string {
    return todo.id;
  }
}

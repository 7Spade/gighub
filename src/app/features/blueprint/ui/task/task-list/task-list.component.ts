/**
 * Task List Component
 *
 * Container component for task module
 * Provides view toggle between tree and table views
 * Supports CRUD operations with modal dialogs
 *
 * @module features/blueprint/ui/task/task-list
 */

import { Component, inject, signal, computed, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { SHARED_IMPORTS } from '@shared';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzModalService } from 'ng-zorro-antd/modal';
import { NzTreeViewModule } from 'ng-zorro-antd/tree-view';
import { SupabaseService } from '@core';

import { TaskStore } from '../../../data-access';
import { TaskModel, TaskViewMode, CreateTaskRequest, UpdateTaskRequest } from '../../../domain';
import { TaskStatus, TaskPriority } from '../../../domain/types';
import { TaskTableComponent } from '../task-table';
import { TaskTreeComponent } from '../task-tree';

/**
 * Task List Component
 *
 * Container managing view toggle and statistics display
 * Handles CRUD operations via modal dialogs
 */
@Component({
  selector: 'app-task-list',
  standalone: true,
  imports: [SHARED_IMPORTS, NzTreeViewModule, TaskTreeComponent, TaskTableComponent],
  templateUrl: './task-list.component.html',
  styleUrl: './task-list.component.less'
})
export class TaskListComponent implements OnInit {
  private readonly taskStore = inject(TaskStore);
  private readonly route = inject(ActivatedRoute);
  private readonly modal = inject(NzModalService);
  private readonly message = inject(NzMessageService);
  private readonly supabase = inject(SupabaseService);

  /** Reference to task form template */
  @ViewChild('taskFormTpl', { static: true }) taskFormTpl!: TemplateRef<object>;

  /** Store state */
  readonly tasks = this.taskStore.tasks;
  readonly loading = this.taskStore.loading;
  readonly error = this.taskStore.error;
  readonly statistics = this.taskStore.statistics;

  /** Local state */
  readonly viewMode = signal<TaskViewMode>('tree');
  readonly searchTerm = signal<string>('');
  readonly blueprintId = signal<string>('');
  readonly workspaceId = signal<string>('');

  /** Form state for create/edit modal */
  readonly editingTask = signal<TaskModel | null>(null);
  readonly formData = signal<{
    name: string;
    description: string;
    status: TaskStatus;
    priority: TaskPriority;
    dueDate: Date | null;
  }>({
    name: '',
    description: '',
    status: 'pending',
    priority: 'medium',
    dueDate: null
  });

  /** Status and Priority options for form */
  readonly statusOptions: Array<{ label: string; value: TaskStatus }> = [
    { label: '待處理', value: 'pending' },
    { label: '進行中', value: 'in_progress' },
    { label: '已完成', value: 'completed' },
    { label: '已取消', value: 'cancelled' }
  ];

  readonly priorityOptions: Array<{ label: string; value: TaskPriority }> = [
    { label: '低', value: 'low' },
    { label: '中', value: 'medium' },
    { label: '高', value: 'high' },
    { label: '緊急', value: 'urgent' }
  ];

  /** Filtered tasks based on search */
  readonly filteredTasks = computed(() => {
    const allTasks = this.tasks();
    const term = this.searchTerm().toLowerCase();

    if (!term) return allTasks;

    return allTasks.filter(
      task =>
        task.name.toLowerCase().includes(term) ||
        task.description?.toLowerCase().includes(term) ||
        task.tags.some(tag => tag.toLowerCase().includes(term))
    );
  });

  ngOnInit(): void {
    // Get blueprintId from query parameters
    this.route.queryParams.subscribe(params => {
      const blueprintId = params['blueprintId'];
      if (blueprintId) {
        this.blueprintId.set(blueprintId);
        this.initializeWorkspaceAndLoadTasks(blueprintId);
      }
    });
  }

  /** Initialize workspace for blueprint and load tasks */
  private async initializeWorkspaceAndLoadTasks(blueprintId: string): Promise<void> {
    try {
      // First, check if a workspace exists for this blueprint
      const { data: existingWorkspace, error: fetchError } = await this.supabase.client
        .from('workspaces')
        .select('id')
        .eq('blueprint_id', blueprintId)
        .maybeSingle();

      if (fetchError) {
        console.error('Failed to fetch workspace:', fetchError);
        this.message.error('載入工作區失敗');
        return;
      }

      let workspaceId: string;

      if (existingWorkspace) {
        // Use existing workspace
        workspaceId = existingWorkspace.id;
      } else {
        // Create a new workspace for this blueprint
        const { data: blueprint } = await this.supabase.client
          .from('blueprints')
          .select('name, owner_id, owner_type')
          .eq('id', blueprintId)
          .single();

        if (!blueprint) {
          this.message.error('找不到藍圖');
          return;
        }

        const { data: newWorkspace, error: createError } = await this.supabase.client
          .from('workspaces')
          .insert({
            blueprint_id: blueprintId,
            name: `${blueprint.name} - 工作區`,
            owner_id: blueprint.owner_id,
            owner_type: blueprint.owner_type,
            status: 'active'
          })
          .select('id')
          .single();

        if (createError || !newWorkspace) {
          console.error('Failed to create workspace:', createError);
          this.message.error('建立工作區失敗');
          return;
        }

        workspaceId = newWorkspace.id;
      }

      this.workspaceId.set(workspaceId);
      await this.loadTasks(workspaceId);
    } catch (error) {
      console.error('Failed to initialize workspace:', error);
      this.message.error('初始化工作區失敗');
    }
  }

  /** Load tasks for the given workspace */
  private async loadTasks(workspaceId: string): Promise<void> {
    try {
      await this.taskStore.loadWorkspaceTasks(workspaceId);
    } catch (error) {
      console.error('Failed to load tasks:', error);
    }
  }

  /** Set view mode to tree */
  setTreeView(): void {
    this.viewMode.set('tree');
  }

  /** Set view mode to table */
  setTableView(): void {
    this.viewMode.set('table');
  }

  /** Handle search input */
  onSearch(term: string): void {
    this.searchTerm.set(term);
  }

  /** Handle task selection */
  onTaskSelect(task: TaskModel): void {
    this.taskStore.getTask(task.id);
  }

  /** Handle create task - open modal */
  onCreateTask(): void {
    this.editingTask.set(null);
    this.formData.set({
      name: '',
      description: '',
      status: 'pending',
      priority: 'medium',
      dueDate: null
    });

    this.modal.create({
      nzTitle: '新增任務',
      nzContent: this.taskFormTpl,
      nzWidth: 520,
      nzOkText: '建立',
      nzCancelText: '取消',
      nzOnOk: () => this.saveTask()
    });
  }

  /** Handle task edit - open modal with existing data */
  onEditTask(task: TaskModel): void {
    this.editingTask.set(task);
    this.formData.set({
      name: task.name,
      description: task.description || '',
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate ? new Date(task.dueDate) : null
    });

    this.modal.create({
      nzTitle: '編輯任務',
      nzContent: this.taskFormTpl,
      nzWidth: 520,
      nzOkText: '更新',
      nzCancelText: '取消',
      nzOnOk: () => this.saveTask()
    });
  }

  /** Handle task delete - show confirmation */
  onDeleteTask(task: TaskModel): void {
    this.modal.confirm({
      nzTitle: '確定要刪除此任務嗎？',
      nzContent: `任務「${task.name}」將被永久刪除，此操作無法復原。`,
      nzOkText: '刪除',
      nzOkType: 'primary',
      nzOkDanger: true,
      nzCancelText: '取消',
      nzOnOk: async () => {
        try {
          await this.taskStore.deleteTask(task.id);
          this.message.success('任務已刪除');
        } catch (error) {
          console.error('Failed to delete task:', error);
          this.message.error('刪除失敗');
        }
      }
    });
  }

  /** Save task (create or update) */
  private async saveTask(): Promise<boolean> {
    const data = this.formData();
    const editingTask = this.editingTask();

    if (!data.name.trim()) {
      this.message.warning('請輸入任務名稱');
      return false;
    }

    try {
      if (editingTask) {
        // Update existing task
        const updateRequest: UpdateTaskRequest = {
          name: data.name.trim(),
          description: data.description.trim() || undefined,
          status: data.status,
          priority: data.priority,
          dueDate: data.dueDate ?? undefined
        };
        await this.taskStore.updateTask(editingTask.id, updateRequest);
        this.message.success('任務已更新');
      } else {
        // Create new task
        const workspaceId = this.workspaceId();
        if (!workspaceId) {
          this.message.error('缺少工作區 ID');
          return false;
        }

        const createRequest: CreateTaskRequest = {
          workspaceId: workspaceId,
          name: data.name.trim(),
          description: data.description.trim() || undefined,
          priority: data.priority,
          dueDate: data.dueDate ?? undefined
        };
        await this.taskStore.createTask(createRequest);
        this.message.success('任務已建立');
      }
      return true;
    } catch (error) {
      console.error('Failed to save task:', error);
      this.message.error(editingTask ? '任務更新失敗' : '任務建立失敗');
      return false;
    }
  }

  /** Update form data field */
  updateFormField(field: string, value: unknown): void {
    this.formData.update(data => ({ ...data, [field]: value }));
  }
}

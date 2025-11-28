/**
 * Task Form Dialog Component
 *
 * Modal dialog for creating/editing tasks (任務表單對話框)
 * Using @delon/form for dynamic form generation
 * Following enterprise guidelines and vertical slice architecture
 * Aligned with SETC-05 specification
 *
 * Dependency flow:
 * Component → Store (Facade) → Service → Repository
 *
 * @module features/blueprint/shell/dialogs/task-form-dialog
 */

import { Component, inject, OnInit, signal, ViewChild } from '@angular/core';
import { SFComponent, SFSchema, SFUISchema } from '@delon/form';
import { SHARED_IMPORTS } from '@shared';
import { format, isDate } from 'date-fns';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NZ_MODAL_DATA, NzModalRef } from 'ng-zorro-antd/modal';

import { TaskStore } from '../../../data-access';
import { TaskModel, CreateTaskRequest, UpdateTaskRequest, TaskPriority, TaskStatus, TaskType } from '../../../domain';

/**
 * Dialog mode for create/edit
 */
export type TaskFormMode = 'create' | 'edit';

/**
 * Dialog input data
 */
export interface TaskFormDialogData {
  mode: TaskFormMode;
  task?: TaskModel;
  blueprintId: string;
  parentId?: string | null;
  createdBy: string;
}

/**
 * Form values interface - Per SETC-05
 */
interface TaskFormValues {
  name: string;
  description?: string;
  priority: TaskPriority;
  status?: TaskStatus;
  taskType: TaskType;
  area?: string;
  tags?: string;
  startDate?: Date;
  dueDate?: Date;
  weight?: number;
}

/**
 * Task Form Dialog Component
 *
 * Smart component for task CRUD operations
 * Uses @delon/form for schema-driven forms
 */
@Component({
  selector: 'app-task-form-dialog',
  standalone: true,
  imports: [SHARED_IMPORTS],
  templateUrl: './task-form-dialog.component.html'
})
export class TaskFormDialogComponent implements OnInit {
  @ViewChild('sf') sf!: SFComponent;

  private readonly modalRef = inject(NzModalRef);
  private readonly messageService = inject(NzMessageService);
  private readonly taskStore = inject(TaskStore);
  private readonly dialogData = inject<TaskFormDialogData>(NZ_MODAL_DATA);

  // Form state
  readonly loading = signal<boolean>(false);
  readonly formData = signal<Partial<TaskFormValues>>({});

  // Dialog properties
  readonly mode = this.dialogData.mode;
  readonly isEditMode = this.mode === 'edit';
  readonly dialogTitle = this.isEditMode ? '編輯任務' : '建立任務';

  /**
   * Form schema definition (JSON Schema) - Per SETC-05
   */
  readonly schema: SFSchema = {
    properties: {
      name: {
        type: 'string',
        title: '任務名稱',
        minLength: 1,
        maxLength: 200
      },
      description: {
        type: 'string',
        title: '描述',
        maxLength: 1000
      },
      taskType: {
        type: 'string',
        title: '任務類型',
        enum: [
          { label: '任務', value: 'task' },
          { label: '里程碑', value: 'milestone' },
          { label: '缺陷', value: 'bug' },
          { label: '功能', value: 'feature' },
          { label: '改進', value: 'improvement' }
        ],
        default: 'task'
      },
      priority: {
        type: 'string',
        title: '優先級',
        enum: [
          { label: '最低', value: 'lowest' },
          { label: '低', value: 'low' },
          { label: '中', value: 'medium' },
          { label: '高', value: 'high' },
          { label: '最高', value: 'highest' }
        ],
        default: 'medium'
      },
      status: {
        type: 'string',
        title: '狀態',
        enum: [
          { label: '待處理', value: 'pending' },
          { label: '進行中', value: 'in_progress' },
          { label: '審核中', value: 'in_review' },
          { label: '已完成', value: 'completed' },
          { label: '已取消', value: 'cancelled' },
          { label: '已阻塞', value: 'blocked' }
        ],
        default: 'pending'
      },
      area: {
        type: 'string',
        title: '區域',
        maxLength: 100
      },
      tags: {
        type: 'string',
        title: '標籤'
      },
      startDate: {
        type: 'string',
        title: '開始日期',
        format: 'date'
      },
      dueDate: {
        type: 'string',
        title: '截止日期',
        format: 'date'
      },
      weight: {
        type: 'number',
        title: '權重',
        minimum: 0,
        maximum: 100,
        default: 1
      }
    },
    required: ['name', 'priority', 'taskType']
  };

  /**
   * UI schema for form layout
   */
  readonly uiSchema: SFUISchema = {
    '*': {
      spanLabelFixed: 100,
      grid: { span: 24 }
    },
    $name: {
      widget: 'string',
      placeholder: '請輸入任務名稱'
    },
    $description: {
      widget: 'textarea',
      placeholder: '請輸入任務描述（選填）',
      autosize: { minRows: 2, maxRows: 4 }
    },
    $taskType: {
      widget: 'select',
      placeholder: '請選擇任務類型'
    },
    $priority: {
      widget: 'select',
      placeholder: '請選擇優先級'
    },
    $status: {
      widget: 'select',
      placeholder: '請選擇狀態'
    },
    $area: {
      widget: 'string',
      placeholder: '請輸入區域（選填）'
    },
    $tags: {
      widget: 'string',
      placeholder: '輸入標籤，用逗號分隔'
    },
    $startDate: {
      widget: 'date',
      placeholder: '請選擇開始日期'
    },
    $dueDate: {
      widget: 'date',
      placeholder: '請選擇截止日期'
    },
    $weight: {
      widget: 'number',
      placeholder: '請輸入權重'
    }
  };

  ngOnInit(): void {
    // Initialize form data for edit mode
    if (this.isEditMode && this.dialogData.task) {
      const task = this.dialogData.task;
      this.formData.set({
        name: task.name,
        description: task.description,
        taskType: task.taskType,
        priority: task.priority,
        status: task.status,
        area: task.area,
        tags: task.tags?.join(','),
        startDate: task.startDate ? new Date(task.startDate) : undefined,
        dueDate: task.dueDate ? new Date(task.dueDate) : undefined,
        weight: task.weight
      });
    } else {
      // Default values for create mode
      this.formData.set({
        priority: 'medium',
        status: 'pending',
        taskType: 'task',
        weight: 1
      });
    }
  }

  /**
   * Trigger form submit programmatically
   */
  triggerSubmit(): void {
    if (this.sf?.valid) {
      this.onSubmit(this.sf.value as TaskFormValues);
    } else {
      // Show validation errors
      this.messageService.warning('請填寫所有必填欄位');
    }
  }

  /**
   * Handle form submission
   */
  async onSubmit(formValue: TaskFormValues): Promise<void> {
    this.loading.set(true);

    try {
      // Parse tags from string
      const tags = this.parseTags(formValue.tags);

      if (this.isEditMode) {
        await this.handleUpdate(formValue, tags);
      } else {
        await this.handleCreate(formValue, tags);
      }
    } catch (error) {
      console.error('Task form error:', error);
      this.messageService.error('操作失敗，請稍後再試');
    } finally {
      this.loading.set(false);
    }
  }

  /**
   * Convert Date to ISO string
   */
  private formatDateToString(date: Date | undefined): string | undefined {
    if (!date) return undefined;
    if (isDate(date)) {
      return format(date, 'yyyy-MM-dd');
    }
    return undefined;
  }

  /**
   * Handle task creation
   */
  private async handleCreate(formValue: TaskFormValues, tags: string[]): Promise<void> {
    const request: CreateTaskRequest = {
      blueprintId: this.dialogData.blueprintId,
      parentId: this.dialogData.parentId,
      name: formValue.name,
      description: formValue.description,
      taskType: formValue.taskType,
      priority: formValue.priority,
      area: formValue.area,
      tags,
      startDate: this.formatDateToString(formValue.startDate),
      dueDate: this.formatDateToString(formValue.dueDate),
      weight: formValue.weight,
      createdBy: this.dialogData.createdBy
    };

    const result = await this.taskStore.createTask(request);
    this.messageService.success('任務建立成功');
    this.modalRef.close(result);
  }

  /**
   * Handle task update
   */
  private async handleUpdate(formValue: TaskFormValues, tags: string[]): Promise<void> {
    if (!this.dialogData.task) {
      throw new Error('Task not found for update');
    }

    const request: UpdateTaskRequest = {
      name: formValue.name,
      description: formValue.description,
      taskType: formValue.taskType,
      priority: formValue.priority,
      status: formValue.status,
      area: formValue.area,
      tags,
      startDate: this.formatDateToString(formValue.startDate),
      dueDate: this.formatDateToString(formValue.dueDate),
      weight: formValue.weight
    };

    const result = await this.taskStore.updateTask(this.dialogData.task.id, request);
    this.messageService.success('任務更新成功');
    this.modalRef.close(result);
  }

  /**
   * Parse tags from string
   */
  private parseTags(tags: string | undefined): string[] {
    if (!tags) return [];
    return tags
      .split(',')
      .map(tag => tag.trim())
      .filter(tag => tag.length > 0);
  }

  /**
   * Handle cancel action
   */
  onCancel(): void {
    this.modalRef.close();
  }
}

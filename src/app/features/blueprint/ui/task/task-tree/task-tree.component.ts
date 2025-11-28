/**
 * Task Tree Component
 *
 * Tree view for tasks using NzTreeViewModule
 * Displays unlimited depth hierarchy with all task info
 * Aligned with SETC-05 specification
 *
 * @module features/blueprint/ui/task/task-tree
 */

import { FlatTreeControl } from '@angular/cdk/tree';
import { Component, Input, Output, EventEmitter, computed, ChangeDetectionStrategy, Signal, effect } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';
import { NzTreeFlatDataSource, NzTreeFlattener, NzTreeViewModule } from 'ng-zorro-antd/tree-view';

import { Task } from '../../../domain';
import {
  TaskFlatNode,
  TaskChildrenMap,
  buildChildrenMap,
  getChildren,
  getStatusColor,
  getStatusText,
  formatProgress,
  getProgressStatus,
  formatAssigneeInitials
} from '../shared';

/**
 * Task Tree Component
 *
 * Renders tasks in a tree structure using NzTreeView
 * Pre-builds children map for O(1) lookup performance
 */
@Component({
  selector: 'app-task-tree',
  standalone: true,
  imports: [SHARED_IMPORTS, NzTreeViewModule],
  templateUrl: './task-tree.component.html',
  styleUrl: './task-tree.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaskTreeComponent {
  /** Tasks signal from parent */
  @Input({ required: true }) tasks!: Signal<Task[]>;

  /** Task select event */
  @Output() readonly taskSelect = new EventEmitter<Task>();

  /** Task edit event */
  @Output() readonly taskEdit = new EventEmitter<Task>();

  /** Task delete event */
  @Output() readonly taskDelete = new EventEmitter<Task>();

  /** Computed children map for O(1) lookup */
  readonly childrenMap = computed<TaskChildrenMap>(() => buildChildrenMap(this.tasks()));

  /** Root tasks computed from children map */
  readonly rootTasks = computed<Task[]>(() => getChildren(this.childrenMap(), null));

  /** Tree control */
  readonly treeControl = new FlatTreeControl<TaskFlatNode>(
    node => node.level,
    node => node.expandable
  );

  /** Tree flattener - Aligned with SETC-05 */
  private readonly transformer = (task: Task, level: number): TaskFlatNode => {
    const children = getChildren(this.childrenMap(), task.id);
    return {
      id: task.id,
      name: task.name,
      level,
      expandable: children.length > 0,
      status: task.status,
      progress: task.progress,
      assigneeId: task.assigneeId,
      reviewerId: task.reviewerId,
      area: task.area,
      tags: task.tags,
      priority: task.priority,
      taskType: task.taskType,
      task
    };
  };

  /** Flattener for NzTreeView */
  private readonly treeFlattener = new NzTreeFlattener(
    this.transformer,
    node => node.level,
    node => node.expandable,
    task => getChildren(this.childrenMap(), task.id)
  );

  /** Data source for tree */
  readonly dataSource = new NzTreeFlatDataSource(this.treeControl, this.treeFlattener);

  /** Check if node has children */
  hasChild = (_: number, node: TaskFlatNode): boolean => node.expandable;

  /** Utility methods exposed to template */
  getStatusColor = getStatusColor;
  getStatusText = getStatusText;
  formatProgress = formatProgress;
  getProgressStatus = getProgressStatus;
  formatAssigneeInitials = formatAssigneeInitials;

  /** Effect to update data source when tasks signal changes */
  constructor() {
    effect(() => {
      const roots = this.rootTasks();
      this.dataSource.setData(roots);
      this.treeControl.expandAll();
    });
  }

  /** Handle node click */
  onNodeClick(node: TaskFlatNode): void {
    this.taskSelect.emit(node.task);
  }

  /** Handle edit action */
  onEdit(event: Event, node: TaskFlatNode): void {
    event.stopPropagation();
    this.taskEdit.emit(node.task);
  }

  /** Handle delete action */
  onDelete(event: Event, node: TaskFlatNode): void {
    event.stopPropagation();
    this.taskDelete.emit(node.task);
  }
}

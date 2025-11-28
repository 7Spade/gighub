/**
 * Blueprint Routes
 *
 * Route configuration for Blueprint feature module
 * Following vertical slice architecture
 *
 * @module features/blueprint/blueprint.routes
 */

import { Routes } from '@angular/router';

export const BLUEPRINT_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./shell/blueprint-shell/blueprint-shell.component').then(m => m.BlueprintShellComponent),
    data: { title: '藍圖容器' }
  },
  {
    path: 'list',
    loadComponent: () => import('./ui/blueprint-list/blueprint-list.component').then(m => m.BlueprintListComponent),
    data: { title: '藍圖列表' }
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./ui/dashboard/dashboard-shell/dashboard-shell.component').then(m => m.DashboardShellComponent),
    data: { title: '儀表板', titleI18n: 'blueprint.dashboard' }
  },
  {
    path: 'task',
    loadComponent: () => import('./ui/task/task-list/task-list.component').then(m => m.TaskListComponent),
    data: { title: '任務管理' }
  },
  {
    path: 'diary',
    loadComponent: () => import('./ui/diary/diary-list/diary-list.component').then(m => m.DiaryListComponent),
    data: { title: '日誌管理' }
  },
  {
    path: 'todo',
    loadComponent: () => import('./ui/todo/todo-list/todo-list.component').then(m => m.TodoListComponent),
    data: { title: '待辦事項' }
  }
];

export default BLUEPRINT_ROUTES;

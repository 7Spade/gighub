/**
 * Blueprint Routes
 *
 * Route configuration for Blueprint feature module
 * Following vertical slice architecture
 *
 * Structure:
 * - /blueprint/list - Blueprint list (outside shell)
 * - /blueprint/:id - Blueprint shell with nested modules
 *   - /blueprint/:id/dashboard - Dashboard module
 *   - /blueprint/:id/task - Task module
 *   - /blueprint/:id/diary - Diary module
 *   - /blueprint/:id/todo - Todo module
 *
 * @module features/blueprint/blueprint.routes
 */

import { Routes } from '@angular/router';

export const BLUEPRINT_ROUTES: Routes = [
  // Blueprint list - outside shell context
  {
    path: 'list',
    loadComponent: () => import('./ui/blueprint-list/blueprint-list.component').then(m => m.BlueprintListComponent),
    data: { title: '藍圖列表' }
  },
  // Blueprint detail with nested modules
  {
    path: ':id',
    loadComponent: () => import('./shell/blueprint-shell/blueprint-shell.component').then(m => m.BlueprintShellComponent),
    data: { title: '藍圖容器' },
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
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
    ]
  },
  // Default redirect to list
  {
    path: '',
    redirectTo: 'list',
    pathMatch: 'full'
  }
];

export default BLUEPRINT_ROUTES;

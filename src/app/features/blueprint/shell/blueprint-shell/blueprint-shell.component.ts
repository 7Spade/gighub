/**
 * Blueprint Shell Component
 *
 * Main container for Blueprint (邏輯容器)
 * Provides context isolation and data sharing
 * Following vertical slice architecture
 *
 * Purpose:
 * - Data isolation (隔離資料)
 * - Context provision (提供 Context)
 * - Shared context for all modules within blueprint
 * - Modern UX with tabbed navigation
 *
 * @module features/blueprint/shell/blueprint-shell/blueprint-shell.component
 */

import { DatePipe } from '@angular/common';
import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { ActivatedRoute, Router, RouterOutlet, NavigationEnd } from '@angular/router';
import { SHARED_IMPORTS } from '@shared';
import { NzMessageService } from 'ng-zorro-antd/message';
import { filter } from 'rxjs/operators';

import { BlueprintStore } from '../../data-access';

/**
 * Module definition for navigation tabs
 */
interface ModuleDefinition {
  key: string;
  label: string;
  icon: string;
  route: string;
  badge?: number;
}

/**
 * Quick action definition
 */
interface QuickAction {
  key: string;
  label: string;
  icon: string;
  color: string;
}

/**
 * Blueprint Shell Component
 *
 * Logical container for data isolation and context sharing
 * Modern UX skeleton with tabbed navigation and quick actions
 */
@Component({
  selector: 'app-blueprint-shell',
  standalone: true,
  imports: [SHARED_IMPORTS, RouterOutlet, DatePipe],
  templateUrl: './blueprint-shell.component.html',
  styleUrl: './blueprint-shell.component.less'
})
export class BlueprintShellComponent implements OnInit {
  private readonly blueprintStore = inject(BlueprintStore);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly message = inject(NzMessageService);

  // Store state
  readonly blueprints = this.blueprintStore.blueprints;
  readonly selectedBlueprint = this.blueprintStore.selectedBlueprint;
  readonly loading = this.blueprintStore.blueprintLoading;
  readonly error = this.blueprintStore.blueprintError;

  // Local state
  readonly currentBlueprintId = signal<string | null>(null);
  readonly activeModule = signal<string>('dashboard');

  // Module definitions for tabs
  readonly modules: ModuleDefinition[] = [
    { key: 'dashboard', label: '儀表板', icon: 'dashboard', route: 'dashboard' },
    { key: 'task', label: '任務管理', icon: 'project', route: 'task' },
    { key: 'diary', label: '施工日誌', icon: 'book', route: 'diary' },
    { key: 'todo', label: '待辦事項', icon: 'check-square', route: 'todo' }
  ];

  // Quick actions for dashboard
  readonly quickActions: QuickAction[] = [
    { key: 'new-task', label: '新增任務', icon: 'plus-circle', color: '#1890ff' },
    { key: 'new-diary', label: '新增日誌', icon: 'form', color: '#52c41a' },
    { key: 'view-reports', label: '查看報表', icon: 'bar-chart', color: '#722ed1' },
    { key: 'team-members', label: '團隊成員', icon: 'team', color: '#fa8c16' },
    { key: 'settings', label: '藍圖設定', icon: 'setting', color: '#13c2c2' },
    { key: 'export', label: '匯出資料', icon: 'export', color: '#eb2f96' }
  ];

  // Computed: active tab index
  readonly activeTabIndex = computed(() => {
    const active = this.activeModule();
    const index = this.modules.findIndex(m => m.key === active);
    return index >= 0 ? index : 0;
  });

  ngOnInit(): void {
    // Get blueprint ID from route
    this.route.params.subscribe(params => {
      if (params['id']) {
        this.currentBlueprintId.set(params['id']);
        this.loadBlueprint(params['id']);
      }
    });

    // Listen to route changes to update active module
    this.router.events.pipe(filter(event => event instanceof NavigationEnd)).subscribe(() => {
      this.updateActiveModule();
    });

    // Initial module detection
    this.updateActiveModule();
  }

  /**
   * Update active module based on current route
   */
  private updateActiveModule(): void {
    const url = this.router.url;
    const module = this.modules.find(m => url.includes(`/${m.route}`));
    if (module) {
      this.activeModule.set(module.key);
    } else {
      this.activeModule.set('dashboard');
    }
  }

  /**
   * Load blueprint by ID
   */
  private async loadBlueprint(id: string): Promise<void> {
    try {
      await this.blueprintStore.getBlueprint(id);
    } catch (error) {
      console.error('Failed to load blueprint:', error);
    }
  }

  /**
   * Handle tab change
   */
  onTabChange(index: number): void {
    const module = this.modules[index];
    if (module) {
      this.navigateToModule(module.route);
    }
  }

  /**
   * Navigate to module
   */
  navigateToModule(module: string): void {
    this.router.navigate([module], { relativeTo: this.route });
  }

  /**
   * Handle quick action click
   */
  onQuickAction(actionKey: string): void {
    switch (actionKey) {
      case 'new-task':
        this.navigateToModule('task');
        this.message.info('請在任務模組中建立新任務');
        break;
      case 'new-diary':
        this.navigateToModule('diary');
        this.message.info('請在日誌模組中建立新日誌');
        break;
      case 'view-reports':
        this.navigateToModule('dashboard');
        break;
      case 'team-members':
        this.inviteMembers();
        break;
      case 'settings':
        this.openSettings();
        break;
      case 'export':
        this.exportBlueprint();
        break;
      default:
        this.message.info(`功能開發中：${actionKey}`);
    }
  }

  /**
   * Get module icon by key
   */
  getModuleIcon(key: string): string {
    const module = this.modules.find(m => m.key === key);
    return module?.icon || 'appstore';
  }

  /**
   * Get module label by key
   */
  getModuleLabel(key: string): string {
    const module = this.modules.find(m => m.key === key);
    return module?.label || '';
  }

  /**
   * Get status color
   */
  getStatusColor(status: string): string {
    const colors: Record<string, string> = {
      draft: 'default',
      active: 'processing',
      archived: 'warning',
      deleted: 'error'
    };
    return colors[status] || 'default';
  }

  /**
   * Get status label
   */
  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      draft: '草稿',
      active: '啟用中',
      archived: '已歸檔',
      deleted: '已刪除'
    };
    return labels[status] || status;
  }

  /**
   * Get visibility color
   */
  getVisibilityColor(visibility: string): string {
    const colors: Record<string, string> = {
      private: 'default',
      internal: 'blue',
      public: 'green'
    };
    return colors[visibility] || 'default';
  }

  /**
   * Get visibility label
   */
  getVisibilityLabel(visibility: string): string {
    const labels: Record<string, string> = {
      private: '私有',
      internal: '內部',
      public: '公開'
    };
    return labels[visibility] || visibility;
  }

  /**
   * Retry loading blueprint
   */
  retryLoad(): void {
    const id = this.currentBlueprintId();
    if (id) {
      this.loadBlueprint(id);
    }
  }

  /**
   * Go back to blueprint list
   */
  goBack(): void {
    this.router.navigate(['/blueprint/list']);
  }

  /**
   * Open blueprint settings
   */
  openSettings(): void {
    this.message.info('藍圖設定功能開發中');
  }

  /**
   * Invite members to blueprint
   */
  inviteMembers(): void {
    this.message.info('邀請成員功能開發中');
  }

  /**
   * Export blueprint data
   */
  exportBlueprint(): void {
    this.message.info('匯出功能開發中');
  }

  /**
   * Archive blueprint
   */
  archiveBlueprint(): void {
    this.message.info('歸檔功能開發中');
  }
}

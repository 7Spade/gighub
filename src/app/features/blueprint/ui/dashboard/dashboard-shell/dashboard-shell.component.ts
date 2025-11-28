/**
 * Dashboard Shell Component
 *
 * Container component for Blueprint Dashboard
 * Provides overview of blueprint activities, progress, and key metrics
 *
 * Following vertical slice architecture pattern
 *
 * @module features/blueprint/ui/dashboard/dashboard-shell
 */

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject, signal, computed } from '@angular/core';
import { G2CardModule } from '@delon/chart/card';
import { G2MiniAreaModule } from '@delon/chart/mini-area';
import { G2MiniBarModule } from '@delon/chart/mini-bar';
import { G2MiniProgressModule } from '@delon/chart/mini-progress';
import { NumberInfoModule } from '@delon/chart/number-info';
import { G2PieModule } from '@delon/chart/pie';
import { TrendModule } from '@delon/chart/trend';
import { _HttpClient } from '@delon/theme';
import { SHARED_IMPORTS } from '@shared';
import { NzAvatarModule } from 'ng-zorro-antd/avatar';
import { NzMessageService } from 'ng-zorro-antd/message';
import { NzProgressModule } from 'ng-zorro-antd/progress';

/**
 * Dashboard Shell Component
 *
 * Main container for blueprint dashboard displaying:
 * - Task statistics overview
 * - Progress charts
 * - Recent activities
 * - Quick access links
 */
@Component({
  selector: 'app-dashboard-shell',
  standalone: true,
  imports: [
    ...SHARED_IMPORTS,
    NzAvatarModule,
    NzProgressModule,
    G2MiniAreaModule,
    G2MiniBarModule,
    G2MiniProgressModule,
    G2PieModule,
    NumberInfoModule,
    TrendModule,
    G2CardModule
  ],
  templateUrl: './dashboard-shell.component.html',
  styleUrl: './dashboard-shell.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DashboardShellComponent implements OnInit {
  private readonly http = inject(_HttpClient);
  readonly msg = inject(NzMessageService);
  private readonly cdr = inject(ChangeDetectorRef);

  /** Loading state */
  readonly loading = signal(true);

  /** Task statistics */
  readonly taskStats = signal<TaskStats>({
    total: 0,
    pending: 0,
    inProgress: 0,
    completed: 0,
    overdue: 0
  });

  /** Task completion rate */
  readonly completionRate = computed(() => {
    const stats = this.taskStats();
    if (stats.total === 0) return 0;
    return Math.round((stats.completed / stats.total) * 100);
  });

  /** Task progress data for pie chart */
  readonly taskProgressData = signal<Array<{ x: string; y: number }>>([]);

  /** Daily progress trend data */
  readonly progressTrendData = signal<Array<{ x: string; y: number }>>([]);

  /** Recent activities */
  readonly recentActivities = signal<RecentActivity[]>([]);

  /** Selected trend period (week/month) */
  selectedTrendPeriod = 'week';

  /** Quick access links */
  readonly quickLinks = [
    { title: '新建任務', icon: 'plus-circle', action: 'createTask' },
    { title: '日誌記錄', icon: 'file-text', action: 'createDiary' },
    { title: '待辦事項', icon: 'check-square', action: 'viewTodos' },
    { title: '任務列表', icon: 'unordered-list', action: 'viewTasks' },
    { title: '進度報表', icon: 'bar-chart', action: 'viewReport' },
    { title: '團隊成員', icon: 'team', action: 'viewTeam' }
  ];

  /** Team members */
  readonly teamMembers = [
    { id: '1', name: '工程師 A', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/WdGqmHpayyMjiEhcKoVE.png', role: '工地主任' },
    { id: '2', name: '工程師 B', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/zOsKZmFRdUtvpqCImOVY.png', role: '施工人員' },
    { id: '3', name: '工程師 C', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/dURIMkkrRFpPgTuzkwnB.png', role: '品管人員' },
    { id: '4', name: '工程師 D', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/sfjbOqnsXXJgNCjCzDBL.png', role: '施工人員' }
  ];

  ngOnInit(): void {
    this.loadDashboardData();
  }

  /**
   * Load dashboard data from mock API
   */
  private loadDashboardData(): void {
    this.loading.set(true);

    this.http.get('/api/blueprint/dashboard').subscribe({
      next: (data: DashboardResponse) => {
        this.taskStats.set(data.taskStats);
        this.taskProgressData.set(data.taskProgressData);
        this.progressTrendData.set(data.progressTrendData);
        this.recentActivities.set(data.recentActivities);
        this.loading.set(false);
        this.cdr.detectChanges();
      },
      error: () => {
        this.loadMockData();
        this.loading.set(false);
        this.cdr.detectChanges();
      }
    });
  }

  /**
   * Load mock data as fallback
   */
  private loadMockData(): void {
    this.taskStats.set({
      total: 128,
      pending: 32,
      inProgress: 45,
      completed: 48,
      overdue: 3
    });

    this.taskProgressData.set([
      { x: '待處理', y: 32 },
      { x: '進行中', y: 45 },
      { x: '已完成', y: 48 },
      { x: '已逾期', y: 3 }
    ]);

    const trend: Array<{ x: string; y: number }> = [];
    for (let i = 0; i < 14; i++) {
      const date = new Date();
      date.setDate(date.getDate() - (13 - i));
      trend.push({
        x: `${date.getMonth() + 1}/${date.getDate()}`,
        y: Math.floor(Math.random() * 10) + 1
      });
    }
    this.progressTrendData.set(trend);

    this.recentActivities.set([
      {
        id: '1',
        user: { name: '工程師 A', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/WdGqmHpayyMjiEhcKoVE.png' },
        action: '完成任務',
        target: '地基開挖作業',
        time: new Date(Date.now() - 30 * 60 * 1000)
      },
      {
        id: '2',
        user: { name: '工程師 B', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/zOsKZmFRdUtvpqCImOVY.png' },
        action: '新增日誌',
        target: '12月27日施工日誌',
        time: new Date(Date.now() - 2 * 60 * 60 * 1000)
      },
      {
        id: '3',
        user: { name: '工程師 C', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/dURIMkkrRFpPgTuzkwnB.png' },
        action: '品質驗收',
        target: '鋼筋綁紮檢查',
        time: new Date(Date.now() - 4 * 60 * 60 * 1000)
      },
      {
        id: '4',
        user: { name: '工程師 D', avatar: 'https://gw.alipayobjects.com/zos/rmsportal/sfjbOqnsXXJgNCjCzDBL.png' },
        action: '更新進度',
        target: '模板組立作業',
        time: new Date(Date.now() - 6 * 60 * 60 * 1000)
      }
    ]);
  }

  /**
   * Handle quick link click
   */
  onQuickLinkClick(action: string): void {
    this.msg.info(`功能開發中: ${action}`);
  }

  /**
   * Handle view all tasks
   */
  onViewAllTasks(): void {
    this.msg.info('查看所有任務');
  }

  /**
   * Handle view all activities
   */
  onViewAllActivities(): void {
    this.msg.info('查看所有動態');
  }

  /**
   * Handle member click
   */
  onMemberClick(member: TeamMember): void {
    this.msg.info(`查看成員: ${member.name}`);
  }

  /**
   * Get time ago string
   */
  getTimeAgo(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (minutes < 60) {
      return `${minutes} 分鐘前`;
    } else if (hours < 24) {
      return `${hours} 小時前`;
    } else {
      return `${days} 天前`;
    }
  }

  /**
   * Track by function for activities
   */
  trackByActivity(_index: number, activity: RecentActivity): string {
    return activity.id;
  }

  /**
   * Track by function for members
   */
  trackByMember(_index: number, member: TeamMember): string {
    return member.id;
  }
}

/** Task statistics interface */
interface TaskStats {
  total: number;
  pending: number;
  inProgress: number;
  completed: number;
  overdue: number;
}

/** Recent activity interface */
interface RecentActivity {
  id: string;
  user: { name: string; avatar: string };
  action: string;
  target: string;
  time: Date;
}

/** Team member interface */
interface TeamMember {
  id: string;
  name: string;
  avatar: string;
  role: string;
}

/** Dashboard API response interface */
interface DashboardResponse {
  taskStats: TaskStats;
  taskProgressData: Array<{ x: string; y: number }>;
  progressTrendData: Array<{ x: string; y: number }>;
  recentActivities: RecentActivity[];
}

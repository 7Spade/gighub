/**
 * Blueprint Dashboard Mock Data
 *
 * Mock data for blueprint dashboard API endpoints
 * Following @delon mock patterns
 */

import { format, subDays } from 'date-fns';

// Task statistics
const taskStats = {
  total: 128,
  pending: 32,
  inProgress: 45,
  completed: 48,
  overdue: 3
};

// Task progress data for pie chart
const taskProgressData = [
  { x: '待處理', y: 32 },
  { x: '進行中', y: 45 },
  { x: '已完成', y: 48 },
  { x: '已逾期', y: 3 }
];

// Generate progress trend data for the last 14 days
const generateProgressTrendData = () => {
  const data: Array<{ x: string; y: number }> = [];
  const now = new Date();

  for (let i = 13; i >= 0; i--) {
    const date = subDays(now, i);
    data.push({
      x: format(date, 'MM/dd'),
      y: Math.floor(Math.random() * 8) + 2
    });
  }
  return data;
};

// User avatars
const avatars = [
  'https://gw.alipayobjects.com/zos/rmsportal/WdGqmHpayyMjiEhcKoVE.png',
  'https://gw.alipayobjects.com/zos/rmsportal/zOsKZmFRdUtvpqCImOVY.png',
  'https://gw.alipayobjects.com/zos/rmsportal/dURIMkkrRFpPgTuzkwnB.png',
  'https://gw.alipayobjects.com/zos/rmsportal/sfjbOqnsXXJgNCjCzDBL.png'
];

// Recent activities
const generateRecentActivities = () => {
  const activities = [
    { user: '工程師 A', action: '完成任務', target: '地基開挖作業', minutesAgo: 30 },
    { user: '工程師 B', action: '新增日誌', target: '12月27日施工日誌', minutesAgo: 120 },
    { user: '工程師 C', action: '品質驗收', target: '鋼筋綁紮檢查', minutesAgo: 240 },
    { user: '工程師 D', action: '更新進度', target: '模板組立作業', minutesAgo: 360 },
    { user: '工程師 A', action: '建立任務', target: '混凝土澆置準備', minutesAgo: 480 },
    { user: '工程師 B', action: '新增待辦', target: '施工計畫審查', minutesAgo: 600 },
    { user: '工程師 C', action: '上傳照片', target: '現場施工進度', minutesAgo: 720 },
    { user: '工程師 D', action: '完成驗收', target: '水電配管工程', minutesAgo: 840 }
  ];

  return activities.map((activity, index) => ({
    id: `${index + 1}`,
    user: {
      name: activity.user,
      avatar: avatars[index % avatars.length]
    },
    action: activity.action,
    target: activity.target,
    time: new Date(Date.now() - activity.minutesAgo * 60 * 1000).toISOString()
  }));
};

// Team members
const teamMembers = [
  { id: '1', name: '工程師 A', avatar: avatars[0], role: '工地主任', status: 'online' },
  { id: '2', name: '工程師 B', avatar: avatars[1], role: '施工人員', status: 'online' },
  { id: '3', name: '工程師 C', avatar: avatars[2], role: '品管人員', status: 'offline' },
  { id: '4', name: '工程師 D', avatar: avatars[3], role: '施工人員', status: 'online' }
];

// Upcoming tasks
const upcomingTasks = [
  { id: '1', title: '混凝土澆置', dueDate: format(new Date(Date.now() + 86400000), 'yyyy-MM-dd'), priority: 'high' },
  { id: '2', title: '鋼筋檢查', dueDate: format(new Date(Date.now() + 172800000), 'yyyy-MM-dd'), priority: 'medium' },
  { id: '3', title: '模板拆除', dueDate: format(new Date(Date.now() + 259200000), 'yyyy-MM-dd'), priority: 'low' }
];

// Export mock API endpoints
export const BLUEPRINT_DASHBOARD = {
  'GET /api/blueprint/dashboard': () => ({
    taskStats,
    taskProgressData,
    progressTrendData: generateProgressTrendData(),
    recentActivities: generateRecentActivities()
  }),
  'GET /api/blueprint/dashboard/stats': () => taskStats,
  'GET /api/blueprint/dashboard/activities': () => generateRecentActivities(),
  'GET /api/blueprint/dashboard/team': () => teamMembers,
  'GET /api/blueprint/dashboard/upcoming': () => upcomingTasks,
  'GET /api/blueprint/dashboard/trend': () => generateProgressTrendData()
};

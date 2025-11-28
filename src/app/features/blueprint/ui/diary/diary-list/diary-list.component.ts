/**
 * Diary List Component
 *
 * Container component for diary module
 * Displays list of diary entries with filtering
 *
 * @module features/blueprint/ui/diary/diary-list
 */

import { Component, inject, signal, computed, ChangeDetectionStrategy, OnInit } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';

import { DiaryStore } from '../../../data-access';
import { DiaryViewModel } from '../../../domain';

/**
 * Diary List Component
 *
 * Container managing diary list display and filtering
 */
@Component({
  selector: 'app-diary-list',
  standalone: true,
  imports: [SHARED_IMPORTS],
  templateUrl: './diary-list.component.html',
  styleUrl: './diary-list.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DiaryListComponent implements OnInit {
  private readonly diaryStore = inject(DiaryStore);

  /** Store state */
  readonly diaries = this.diaryStore.diaries;
  readonly diaryViewModels = this.diaryStore.diaryViewModels;
  readonly loading = this.diaryStore.loading;
  readonly error = this.diaryStore.error;
  readonly statistics = this.diaryStore.statistics;

  /** Local state */
  readonly searchTerm = signal<string>('');
  readonly selectedMonth = signal<Date>(new Date());

  /** Filtered diaries based on search and month */
  readonly filteredDiaries = computed(() => {
    const allDiaries = this.diaryViewModels();
    const term = this.searchTerm().toLowerCase();
    const month = this.selectedMonth();

    let filtered = allDiaries;

    // Filter by month
    if (month) {
      filtered = filtered.filter(d => {
        const diaryDate = new Date(d.date);
        return diaryDate.getMonth() === month.getMonth() && diaryDate.getFullYear() === month.getFullYear();
      });
    }

    // Filter by search term
    if (term) {
      filtered = filtered.filter(
        d => d.title.toLowerCase().includes(term) || d.summary.toLowerCase().includes(term) || d.authorName.toLowerCase().includes(term)
      );
    }

    return filtered;
  });

  // eslint-disable-next-line @angular-eslint/no-empty-lifecycle-method
  ngOnInit(): void {
    // Load initial data - would need workspaceId from context
    // this.diaryStore.loadWorkspaceDiaries(workspaceId);
  }

  /** Handle search input */
  onSearch(term: string): void {
    this.searchTerm.set(term);
  }

  /** Handle month change */
  onMonthChange(date: Date): void {
    this.selectedMonth.set(date);
  }

  /** Handle create diary */
  onCreateDiary(): void {
    // TODO: Open diary creation dialog
    console.log('Create diary clicked');
  }

  /** Handle view diary */
  onViewDiary(diary: DiaryViewModel): void {
    // TODO: Navigate to diary detail or open dialog
    console.log('View diary:', diary.id);
  }

  /** Handle edit diary */
  onEditDiary(diary: DiaryViewModel): void {
    // TODO: Open diary edit dialog
    console.log('Edit diary:', diary.id);
  }

  /** Handle delete diary */
  onDeleteDiary(diary: DiaryViewModel): void {
    // TODO: Show delete confirmation dialog
    console.log('Delete diary:', diary.id);
  }

  /** Get weather icon class */
  getWeatherIcon(weather: string): string {
    const icons: Record<string, string> = {
      sunny: 'smile',
      cloudy: 'cloud',
      rainy: 'cloud-download',
      stormy: 'thunderbolt',
      snowy: 'cloud',
      foggy: 'eye-invisible',
      unknown: 'question-circle'
    };
    return icons[weather] || 'question-circle';
  }

  /** Track by function for ngFor */
  trackByDiary(_index: number, diary: DiaryViewModel): string {
    return diary.id;
  }
}

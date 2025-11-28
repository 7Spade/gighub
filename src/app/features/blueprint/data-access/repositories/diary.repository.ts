/**
 * Diary Repository
 *
 * Repository for Diary data access layer
 * Following vertical slice architecture
 *
 * @module features/blueprint/data-access/repositories/diary.repository
 */

import { Injectable } from '@angular/core';
import { BaseRepository, QueryOptions } from '@core';
import { Observable } from 'rxjs';

import { Diary, DiaryInsert, DiaryUpdate } from '../../domain';

/**
 * Diary Repository
 *
 * Handles data access for diaries with automatic camelCase conversion
 */
@Injectable({ providedIn: 'root' })
export class DiaryRepository extends BaseRepository<Diary, DiaryInsert, DiaryUpdate> {
  protected tableName = 'diaries';

  /**
   * Find diaries by workspace
   *
   * @param {string} workspaceId - Workspace ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Diary[]>} Array of diaries
   */
  findByWorkspace(workspaceId: string, options?: QueryOptions): Observable<Diary[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        workspaceId
      },
      order: { column: 'date', ascending: false }
    });
  }

  /**
   * Find diaries by blueprint
   *
   * @param {string} blueprintId - Blueprint ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Diary[]>} Array of diaries
   */
  findByBlueprint(blueprintId: string, options?: QueryOptions): Observable<Diary[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        blueprintId
      },
      order: { column: 'date', ascending: false }
    });
  }

  /**
   * Find diary by workspace and date
   *
   * @param {string} workspaceId - Workspace ID
   * @param {Date} date - Date
   * @returns {Observable<Diary | null>} Diary or null
   */
  findByWorkspaceAndDate(workspaceId: string, date: Date): Observable<Diary | null> {
    const dateStr = formatDateForDb(date);
    return this.findOne({
      workspaceId,
      date: dateStr
    });
  }

  /**
   * Find diaries by date range
   *
   * @param {string} workspaceId - Workspace ID
   * @param {Date} _startDate - Start date (reserved for future implementation)
   * @param {Date} _endDate - End date (reserved for future implementation)
   * @returns {Observable<Diary[]>} Array of diaries
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  findByDateRange(workspaceId: string, _startDate: Date, _endDate: Date): Observable<Diary[]> {
    // Note: Date range filtering requires custom implementation
    // For now, fetch all and filter client-side
    return this.findByWorkspace(workspaceId);
  }

  /**
   * Find diaries by author
   *
   * @param {string} authorId - Author ID
   * @param {QueryOptions} [options] - Query options
   * @returns {Observable<Diary[]>} Array of diaries
   */
  findByAuthor(authorId: string, options?: QueryOptions): Observable<Diary[]> {
    return this.findAll({
      ...options,
      filters: {
        ...options?.filters,
        authorId
      },
      order: { column: 'date', ascending: false }
    });
  }
}

/**
 * Format date for database
 */
function formatDateForDb(date: Date): string {
  const d = new Date(date);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

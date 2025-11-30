/**
 * Team Service
 *
 * 團隊管理服務（Shared 層）
 * Team management service (Shared layer)
 *
 * Provides business logic for team operations using Signals-based state management.
 * Handles team CRUD operations and coordinates with TeamRepository.
 *
 * @module shared/services/account
 */

import { Injectable, inject, signal } from '@angular/core';
import { TeamRepository } from '@core';
import { firstValueFrom } from 'rxjs';

import { TeamBusinessModel, CreateTeamRequest, UpdateTeamRequest } from '../../models/account';
import { ErrorHandlerService } from '../error-handler.service';

@Injectable({
  providedIn: 'root'
})
export class TeamService {
  private readonly teamRepo = inject(TeamRepository);
  private readonly errorHandler = inject(ErrorHandlerService);

  // State
  private teamsState = signal<TeamBusinessModel[]>([]);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);

  // Readonly signals
  readonly teams = this.teamsState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();

  /**
   * 根據 ID 查詢團隊
   * Find team by ID
   *
   * @param {string} id - Team ID
   * @returns {Promise<TeamBusinessModel | null>} Team or null
   */
  async findById(id: string): Promise<TeamBusinessModel | null> {
    return firstValueFrom(this.teamRepo.findById(id)) as Promise<TeamBusinessModel | null>;
  }

  /**
   * 根據組織 ID 查詢團隊
   * Find teams by organization ID
   *
   * @param {string} organizationId - Organization ID
   * @returns {Promise<TeamBusinessModel[]>} Teams in organization
   */
  async findByOrganization(organizationId: string): Promise<TeamBusinessModel[]> {
    const teams = await firstValueFrom(this.teamRepo.findByOrganization(organizationId));
    return teams as TeamBusinessModel[];
  }

  /**
   * 創建團隊
   * Create team
   *
   * @param {CreateTeamRequest} request - Create request
   * @returns {Promise<TeamBusinessModel>} Created team
   */
  async createTeam(request: CreateTeamRequest): Promise<TeamBusinessModel> {
    const client = this.supabaseService.getClient();

    // Use SECURITY DEFINER function to create team atomically
    // This bypasses RLS policies and ensures proper permission checks
    const { data, error } = await (client as any).rpc('create_team', {
      p_organization_id: request.organizationId,
      p_name: request.name,
      p_description: request.description || null,
      p_metadata: request.avatar ? { avatar: request.avatar } : {}
    });

    if (error) {
      console.error('[TeamService] Failed to create team:', error);
      throw error;
    }

    if (!data || !data[0]) {
      throw new Error('Failed to create team');
    }

    const { team_id } = data[0];

    // Fetch the created team
    const team = await firstValueFrom(this.teamRepo.findById(team_id));
    if (!team) {
      throw new Error('Failed to fetch created team');
    }

    return team as TeamBusinessModel;
  }

  /**
   * 更新團隊
   * Update team
   *
   * @param {string} id - Team ID
   * @param {UpdateTeamRequest} request - Update request
   * @returns {Promise<TeamBusinessModel>} Updated team
   */
  async updateTeam(id: string, request: UpdateTeamRequest): Promise<TeamBusinessModel> {
    return firstValueFrom(this.teamRepo.update(id, request as any)) as Promise<TeamBusinessModel>;
  }

  /**
   * 刪除團隊
   * Delete team
   *
   * @param {string} id - Team ID
   * @returns {Promise<void>} Void
   */
  async deleteTeam(id: string): Promise<void> {
    return firstValueFrom(this.teamRepo.delete(id));
  }

  /**
   * 載入組織的團隊列表
   * Load teams for organization
   *
   * @param {string} organizationId - Organization ID
   */
  async loadTeamsByOrganization(organizationId: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const teams = await this.findByOrganization(organizationId);
      this.teamsState.set(teams);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load teams';
      this.errorState.set(errorMessage);
      console.error('[TeamService] Failed to load teams:', error);
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }
}

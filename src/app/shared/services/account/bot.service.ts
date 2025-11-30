/**
 * Bot Service
 *
 * 機器人管理服務（Shared 層）
 * Bot management service (Shared layer)
 *
 * Provides business logic for bot account operations using Signals-based state management.
 * Uses BotRepository for type-safe data access (no runtime type checks needed).
 *
 * @module shared/services/account
 */

import { Injectable, inject, signal } from '@angular/core';
import { BotRepository, AccountStatus, SupabaseService } from '@core';
import { firstValueFrom } from 'rxjs';

import { BotAccountModel, CreateBotRequest, UpdateBotRequest } from '../../models/account';

@Injectable({
  providedIn: 'root'
})
export class BotService {
  private readonly botRepo = inject(BotRepository);
  private readonly supabaseService = inject(SupabaseService);

  // State
  private botsState = signal<BotAccountModel[]>([]);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);

  // Readonly signals
  readonly bots = this.botsState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();

  /**
   * 根據 ID 查詢機器人帳戶
   * Find bot account by ID
   *
   * @param {string} id - Account ID
   * @returns {Promise<BotAccountModel | null>} Bot account or null
   */
  async findById(id: string): Promise<BotAccountModel | null> {
    const account = await firstValueFrom(this.botRepo.findById(id));
    return account as BotAccountModel | null;
  }

  /**
   * 查詢活躍的機器人
   * Find active bots
   *
   * @returns {Promise<BotAccountModel[]>} Active bots
   */
  async findActiveBots(): Promise<BotAccountModel[]> {
    const bots = await firstValueFrom(this.botRepo.findActiveBots());
    return bots as BotAccountModel[];
  }

  /**
   * 創建機器人帳戶
   * Create bot account
   *
   * @param {CreateBotRequest} request - Create request
   * @returns {Promise<BotAccountModel>} Created bot account
   */
  async createBot(request: CreateBotRequest): Promise<BotAccountModel> {
    // Get current user for auth_user_id (required by RLS policy)
    const user = await this.supabaseService.getUser();
    if (!user || !user.id) {
      throw new Error('User not authenticated');
    }

    const insertData = {
      name: request.name,
      email: request.email || null,
      avatar_url: request.avatar || null, // Use avatar_url (existing column) instead of avatar (new column not in cache yet)
      status: request.status || AccountStatus.ACTIVE,
      auth_user_id: user.id // Required by authenticated_users_create_bots policy
    };

    const account = await firstValueFrom(this.botRepo.create(insertData as any));
    return account as BotAccountModel;
  }

  /**
   * 更新機器人帳戶
   * Update bot account
   *
   * @param {string} id - Account ID
   * @param {UpdateBotRequest} request - Update request
   * @returns {Promise<BotAccountModel>} Updated bot account
   */
  async updateBot(id: string, request: UpdateBotRequest): Promise<BotAccountModel> {
    const account = await firstValueFrom(this.botRepo.update(id, request as any));
    return account as BotAccountModel;
  }

  /**
   * 啟用機器人
   * Activate bot
   *
   * @param {string} id - Bot ID
   * @returns {Promise<BotAccountModel>} Updated bot account
   */
  async activateBot(id: string): Promise<BotAccountModel> {
    const account = await firstValueFrom(this.botRepo.activate(id));
    return account as BotAccountModel;
  }

  /**
   * 停用機器人
   * Deactivate bot
   *
   * @param {string} id - Bot ID
   * @returns {Promise<BotAccountModel>} Updated bot account
   */
  async deactivateBot(id: string): Promise<BotAccountModel> {
    const account = await firstValueFrom(this.botRepo.deactivate(id));
    return account as BotAccountModel;
  }

  /**
   * 軟刪除機器人帳戶
   * Soft delete bot account
   *
   * @param {string} id - Account ID
   * @returns {Promise<BotAccountModel>} Updated bot account
   */
  async softDeleteBot(id: string): Promise<BotAccountModel> {
    const account = await firstValueFrom(this.botRepo.softDelete(id));
    return account as BotAccountModel;
  }

  /**
   * 恢復已刪除的機器人帳戶
   * Restore deleted bot account
   *
   * @param {string} id - Account ID
   * @returns {Promise<BotAccountModel>} Updated bot account
   */
  async restoreBot(id: string): Promise<BotAccountModel> {
    const account = await firstValueFrom(this.botRepo.restore(id));
    return account as BotAccountModel;
  }

  /**
   * 載入機器人列表
   * Load bots
   */
  async loadBots(): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const bots = await firstValueFrom(this.botRepo.findAll());

      this.botsState.set(bots as BotAccountModel[]);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load bots';
      this.errorState.set(errorMessage);
      console.error('[BotService] Failed to load bots:', error);
    } finally {
      this.loadingState.set(false);
    }
  }
}

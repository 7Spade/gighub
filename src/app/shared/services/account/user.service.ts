/**
 * User Service
 *
 * 用戶管理服務（Shared 層）
 * User management service (Shared layer)
 *
 * Provides business logic for user account operations using Signals-based state management.
 * Uses UserRepository for type-safe data access (no runtime type checks needed).
 *
 * @module shared/services/account
 */

import { Injectable, inject, signal } from '@angular/core';
import { UserRepository, AccountStatus } from '@core';
import { firstValueFrom } from 'rxjs';

import { UserAccountModel, CreateUserAccountRequest, UpdateUserAccountRequest } from '../../models/account';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private readonly userRepo = inject(UserRepository);

  // State
  private userAccountsState = signal<UserAccountModel[]>([]);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);

  // Readonly signals
  readonly userAccounts = this.userAccountsState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();

  /**
   * 根據 Auth User ID 查詢用戶帳戶
   * Find user account by auth user ID
   *
   * @param {string} authUserId - Auth user ID
   * @returns {Promise<UserAccountModel | null>} User account or null
   */
  async findByAuthUserId(authUserId: string): Promise<UserAccountModel | null> {
    const account = await firstValueFrom(this.userRepo.findByAuthUserId(authUserId));
    return account as UserAccountModel | null;
  }

  /**
   * 根據 ID 查詢用戶帳戶
   * Find user account by ID
   *
   * @param {string} id - Account ID
   * @returns {Promise<UserAccountModel | null>} User account or null
   */
  async findById(id: string): Promise<UserAccountModel | null> {
    const account = await firstValueFrom(this.userRepo.findById(id));
    return account as UserAccountModel | null;
  }

  /**
   * 創建用戶帳戶
   * Create user account
   *
   * @param {CreateUserRequest} request - Create request
   * @returns {Promise<UserAccountModel>} Created user account
   */
  async createUser(request: CreateUserAccountRequest): Promise<UserAccountModel> {
    const insertData = {
      name: request.name,
      email: request.email || null,
      avatar_url: request.avatar || null, // Use avatar_url (existing column) instead of avatar (new column not in cache yet)
      status: request.status || AccountStatus.ACTIVE
    };

    const account = await firstValueFrom(this.userRepo.create(insertData as any));
    return account as UserAccountModel;
  }

  /**
   * 更新用戶帳戶
   * Update user account
   *
   * @param {string} id - Account ID
   * @param {UpdateUserRequest} request - Update request
   * @returns {Promise<UserAccountModel>} Updated user account
   */
  async updateUser(id: string, request: UpdateUserAccountRequest): Promise<UserAccountModel> {
    const account = await firstValueFrom(this.userRepo.update(id, request as any));
    return account as UserAccountModel;
  }

  /**
   * 軟刪除用戶帳戶
   * Soft delete user account
   *
   * @param {string} id - Account ID
   * @returns {Promise<UserAccountModel>} Updated user account
   */
  async softDeleteUser(id: string): Promise<UserAccountModel> {
    const account = await firstValueFrom(this.userRepo.softDelete(id));
    return account as UserAccountModel;
  }

  /**
   * 恢復已刪除的用戶帳戶
   * Restore deleted user account
   *
   * @param {string} id - Account ID
   * @returns {Promise<UserAccountModel>} Updated user account
   */
  async restoreUser(id: string): Promise<UserAccountModel> {
    const account = await firstValueFrom(this.userRepo.restore(id));
    return account as UserAccountModel;
  }

  /**
   * 載入用戶帳戶列表
   * Load user accounts
   *
   * @param {string} authUserId - Auth user ID
   */
  async loadUserAccounts(authUserId: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const accounts = await firstValueFrom(
        this.userRepo.findAll({
          filters: { authUserId: authUserId as any }
        })
      );

      this.userAccountsState.set(accounts as UserAccountModel[]);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load user accounts';
      this.errorState.set(errorMessage);
      console.error('[UserService] Failed to load user accounts:', error);
    } finally {
      this.loadingState.set(false);
    }
  }
}

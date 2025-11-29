/**
 * Organization Service
 *
 * 組織管理服務（Shared 層）
 * Organization management service (Shared layer)
 *
 * Provides business logic for organization operations using Signals-based state management.
 * Handles organization CRUD operations and coordinates with OrganizationRepository and UserRepository.
 *
 * @module shared/services/account
 */

import { Injectable, inject, signal } from '@angular/core';
import {
  AccountStatus,
  OrganizationMemberRole,
  UserRepository,
  SupabaseService,
  OrganizationRepository,
  OrganizationMemberRepository
} from '@core';
import { firstValueFrom } from 'rxjs';

import { OrganizationBusinessModel, CreateOrganizationRequest, UpdateOrganizationRequest } from '../../models/account';
import { ErrorHandlerService } from '../error-handler.service';

@Injectable({
  providedIn: 'root'
})
export class OrganizationService {
  private readonly organizationRepo = inject(OrganizationRepository);
  private readonly organizationMemberRepo = inject(OrganizationMemberRepository);
  private readonly userRepo = inject(UserRepository);
  private readonly supabaseService = inject(SupabaseService);
  private readonly errorHandler = inject(ErrorHandlerService);

  // State
  private organizationsState = signal<OrganizationBusinessModel[]>([]);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);

  // Readonly signals
  readonly organizations = this.organizationsState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();

  /**
   * 根據 ID 查詢組織
   * Find organization by ID
   *
   * @param {string} id - Organization ID
   * @returns {Promise<OrganizationModel | null>} Organization or null
   */
  async findById(id: string): Promise<OrganizationBusinessModel | null> {
    const account = await firstValueFrom(this.organizationRepo.findById(id));
    return account as OrganizationBusinessModel | null;
  }

  /**
   * 查詢用戶創建的組織
   * Find organizations created by user
   *
   * @param {string} authUserId - Auth user ID
   * @returns {Promise<OrganizationBusinessModel[]>} Organizations created by user
   */
  async getUserCreatedOrganizations(authUserId: string): Promise<OrganizationBusinessModel[]> {
    const ownerMemberships = await firstValueFrom(
      this.organizationMemberRepo.findWithOptions({
        authUserId,
        role: OrganizationMemberRole.OWNER
      })
    );

    const organizationIds = ownerMemberships.map(m => (m as any).organization_id).filter(id => id);
    if (organizationIds.length === 0) {
      return [];
    }

    const orgs = await firstValueFrom(this.organizationRepo.findByIds(organizationIds));
    return orgs as OrganizationBusinessModel[];
  }

  /**
   * 查詢用戶加入的組織
   * Find organizations user has joined
   *
   * @param {string} accountId - Account ID
   * @returns {Promise<OrganizationBusinessModel[]>} Organizations user has joined
   */
  async getUserJoinedOrganizations(accountId: string): Promise<OrganizationBusinessModel[]> {
    const memberships = await firstValueFrom(this.organizationMemberRepo.findByAccount(accountId));
    const orgIds = memberships.map(m => (m as any).organization_id).filter(id => id);

    if (orgIds.length === 0) {
      return [];
    }

    const orgs = await firstValueFrom(this.organizationRepo.findByIds(orgIds));
    return orgs as OrganizationBusinessModel[];
  }

  /**
   * 創建組織
   * Create organization
   *
   * Creates a new organization account. The database trigger `add_creator_as_org_owner`
   * automatically adds the creator as an owner in the organization_members table after
   * the INSERT operation completes. This ensures atomic membership creation without the
   * need for manual application-level coordination.
   *
   * @param {CreateOrganizationRequest} request - Create request
   * @returns {Promise<OrganizationBusinessModel>} Created organization
   * @throws {Error} If user is not authenticated, user account not found, or creation fails
   */
  async createOrganization(request: CreateOrganizationRequest): Promise<OrganizationBusinessModel> {
    // 1. 獲取當前用戶的 auth_user_id
    const user = await this.supabaseService.getUser();
    if (!user || !user.id) {
      throw new Error('User not authenticated');
    }

    // 2. 驗證用戶帳號存在（防止創建無主組織）
    // Verify user account exists (prevents creating ownerless organizations)
    const userAccount = await firstValueFrom(this.userRepo.findByAuthUserId(user.id));
    if (!userAccount) {
      throw new Error('User account not found');
    }

    // 3. 創建組織（觸發器會自動將創建者添加為 owner）
    // Create organization (trigger will automatically add creator as owner)
    // auth_user_id: Set to creator's auth.uid() to satisfy SELECT policy after INSERT
    const insertData = {
      name: request.name,
      email: request.email || null,
      // DB column is `avatar_url`; map the DTO `avatar` to `avatar_url` to match schema
      avatar_url: request.avatar || null,
      status: request.status || AccountStatus.ACTIVE,
      auth_user_id: user.id // Required for SELECT policy to return newly created org
    };

    const organization = await firstValueFrom(this.organizationRepo.create(insertData));

    // Note: The database trigger `add_creator_as_org_owner` automatically creates
    // an organization_members record with role='owner' for the creator.
    // No manual membership creation needed here.

    return organization as OrganizationBusinessModel;
  }

  /**
   * 更新組織
   * Update organization
   *
   * @param {string} id - Organization ID
   * @param {UpdateOrganizationRequest} request - Update request
   * @returns {Promise<OrganizationBusinessModel>} Updated organization
   */
  async updateOrganization(id: string, request: UpdateOrganizationRequest): Promise<OrganizationBusinessModel> {
    // Map `avatar` field from DTO to `avatar_url` DB column if present
    const updatePayload: any = { ...request } as any;
    if ((request as any).avatar !== undefined) {
      updatePayload.avatar_url = (request as any).avatar;
      delete updatePayload.avatar;
    }

    const account = await firstValueFrom(this.organizationRepo.update(id, updatePayload as any));
    return account as OrganizationBusinessModel;
  }

  /**
   * 軟刪除組織（設定狀態為 DELETED）
   * Soft delete organization (set status to DELETED)
   *
   * @param {string} id - Organization ID
   * @returns {Promise<OrganizationBusinessModel>} Updated organization
   */
  async softDeleteOrganization(id: string): Promise<OrganizationBusinessModel> {
    const account = await firstValueFrom(this.organizationRepo.softDelete(id));
    return account as OrganizationBusinessModel;
  }

  /**
   * 恢復已刪除的組織
   * Restore deleted organization
   *
   * @param {string} id - Organization ID
   * @returns {Promise<OrganizationBusinessModel>} Updated organization
   */
  async restoreOrganization(id: string): Promise<OrganizationBusinessModel> {
    const account = await firstValueFrom(this.organizationRepo.restore(id));
    return account as OrganizationBusinessModel;
  }

  /**
   * 載入用戶創建的組織列表
   * Load organizations created by user
   *
   * @param {string} authUserId - Auth user ID
   */
  async loadUserCreatedOrganizations(authUserId: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const orgs = await this.getUserCreatedOrganizations(authUserId);
      this.organizationsState.set(orgs);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load organizations';
      this.errorState.set(errorMessage);
      console.error('[OrganizationService] Failed to load organizations:', error);
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }
}

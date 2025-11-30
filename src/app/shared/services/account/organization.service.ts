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
   * 生成 slug 從名稱
   * Generate slug from name
   *
   * Converts name to lowercase, replaces spaces with hyphens, removes special chars
   */
  private generateSlug(name: string): string {
    return name
      .toLowerCase()
      .trim()
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/[^\w\u4e00-\u9fff-]/g, '') // Allow word chars, Chinese chars, and hyphens
      .replace(/-+/g, '-') // Replace multiple hyphens with single
      .replace(/^-|-$/g, ''); // Remove leading/trailing hyphens
  }

  /**
   * 創建組織
   * Create organization
   *
   * Creates a new organization account and organizations table record.
   * The database trigger `handle_new_organization` automatically adds the creator
   * as an owner in the organization_members table after the organizations INSERT
   * operation completes. This ensures atomic membership creation without the
   * need for manual application-level coordination.
   *
   * @param {CreateOrganizationRequest} request - Create request
   * @returns {Promise<OrganizationBusinessModel>} Created organization
   * @throws {Error} If user is not authenticated, user account not found, or creation fails
   */
  async createOrganization(request: CreateOrganizationRequest): Promise<OrganizationBusinessModel> {
    const client = this.supabaseService.getClient();

    // Use SECURITY DEFINER function to create organization atomically
    // This bypasses RLS policies and ensures transactional integrity
    // The function handles: account creation, organization creation, and member assignment
    const { data, error } = await (client as any).rpc('create_organization', {
      p_name: request.name,
      p_email: request.email || null,
      p_avatar_url: request.avatar || null,
      p_slug: null // Let the function generate slug
    });

    if (error) {
      console.error('[OrganizationService] Failed to create organization:', error);
      throw error;
    }

    if (!data || !data[0]) {
      throw new Error('Failed to create organization');
    }

    const { account_id, organization_id } = data[0];

    // Fetch the created organization account
    const { data: accountData, error: fetchError } = await client
      .from('accounts')
      .select('*')
      .eq('id', account_id)
      .single();

    if (fetchError || !accountData) {
      throw new Error('Failed to fetch created organization account');
    }

    return accountData as OrganizationBusinessModel;
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
    const account = await firstValueFrom(this.organizationRepo.update(id, request as any));
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

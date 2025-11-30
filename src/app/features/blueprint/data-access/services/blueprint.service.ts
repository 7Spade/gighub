/**
 * Blueprint Service
 *
 * Business logic for Blueprint Container management
 * Aligned with database schema: 20251129000001_create_multi_tenant_saas_schema.sql
 *
 * Uses Angular Signals for reactive state management
 *
 * @module features/blueprint/data-access/services/blueprint.service
 */

import { Injectable, inject, signal, computed } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { SupabaseService } from '@core';
import { BlueprintModel, CreateBlueprintRequest, UpdateBlueprintRequest, BlueprintStatistics, BlueprintStatusEnum } from '../../domain';
import { BlueprintRepository } from '../repositories';

/**
 * Blueprint Service
 *
 * Manages blueprint state and business logic with Signals
 */
@Injectable({ providedIn: 'root' })
export class BlueprintService {
  private readonly blueprintRepo = inject(BlueprintRepository);
  private readonly supabaseService = inject(SupabaseService);

  // State management with Signals
  private blueprintsState = signal<BlueprintModel[]>([]);
  private selectedBlueprintState = signal<BlueprintModel | null>(null);
  private loadingState = signal<boolean>(false);
  private errorState = signal<string | null>(null);

  // Expose ReadonlySignal to components
  readonly blueprints = this.blueprintsState.asReadonly();
  readonly selectedBlueprint = this.selectedBlueprintState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();

  // Computed signals for derived state
  readonly activeBlueprints = computed(() => this.blueprints().filter(b => b.status === BlueprintStatusEnum.ACTIVE));

  readonly inactiveBlueprints = computed(() => this.blueprints().filter(b => b.status === BlueprintStatusEnum.INACTIVE));

  readonly statistics = computed<BlueprintStatistics>(() => {
    const blueprints = this.blueprints();

    return {
      totalCount: blueprints.length,
      activeCount: blueprints.filter(b => b.status === BlueprintStatusEnum.ACTIVE).length,
      inactiveCount: blueprints.filter(b => b.status === BlueprintStatusEnum.INACTIVE).length
    };
  });

  /**
   * Load blueprints by owner
   */
  async loadBlueprintsByOwner(ownerId: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const blueprints = await firstValueFrom(this.blueprintRepo.findByOwner(ownerId));
      this.blueprintsState.set(blueprints);
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to load blueprints');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Load public blueprints
   */
  async loadPublicBlueprints(): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const blueprints = await firstValueFrom(this.blueprintRepo.findPublicBlueprints());
      this.blueprintsState.set(blueprints);
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to load public blueprints');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Get blueprint by ID
   */
  async getBlueprintById(id: string): Promise<BlueprintModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const blueprint = await firstValueFrom(this.blueprintRepo.findById(id));
      if (!blueprint) {
        throw new Error('Blueprint not found');
      }
      this.selectedBlueprintState.set(blueprint);
      return blueprint;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to load blueprint');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Create new blueprint
   */
  async createBlueprint(request: CreateBlueprintRequest): Promise<BlueprintModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      // Use SECURITY DEFINER function to create blueprint atomically
      // This bypasses RLS policies and ensures proper permission checks
      const client = this.supabaseService.getClient();
      
      const { data, error } = await (client as any).rpc('create_blueprint', {
        p_owner_id: request.ownerId,
        p_name: request.name,
        p_slug: request.slug || null,
        p_description: request.description || null,
        p_cover_url: null,
        p_is_public: request.isPublic ?? false,
        p_enabled_modules: request.enabledModules ?? ['tasks']
      });

      if (error) {
        console.error('[BlueprintService] Failed to create blueprint:', error);
        throw error;
      }

      if (!data || !data[0]) {
        throw new Error('Failed to create blueprint');
      }

      const { blueprint_id } = data[0];

      // Fetch the created blueprint
      const newBlueprint = await firstValueFrom(this.blueprintRepo.findById(blueprint_id));
      if (!newBlueprint) {
        throw new Error('Failed to fetch created blueprint');
      }

      // Update state
      this.blueprintsState.update(blueprints => [...blueprints, newBlueprint]);

      return newBlueprint;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to create blueprint');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Generate slug from name
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
   * Update blueprint
   */
  async updateBlueprint(id: string, request: UpdateBlueprintRequest): Promise<BlueprintModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const updatedBlueprint = await firstValueFrom(this.blueprintRepo.update(id, request));

      // Update state
      this.blueprintsState.update(blueprints => blueprints.map(b => (b.id === id ? updatedBlueprint : b)));

      if (this.selectedBlueprint()?.id === id) {
        this.selectedBlueprintState.set(updatedBlueprint);
      }

      return updatedBlueprint;
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to update blueprint');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Delete blueprint (soft delete by setting status to deleted)
   */
  async deleteBlueprint(id: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      await firstValueFrom(this.blueprintRepo.update(id, { status: BlueprintStatusEnum.DELETED }));

      // Update state
      this.blueprintsState.update(blueprints => blueprints.filter(b => b.id !== id));

      if (this.selectedBlueprint()?.id === id) {
        this.selectedBlueprintState.set(null);
      }
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to delete blueprint');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Deactivate blueprint
   */
  async deactivateBlueprint(id: string): Promise<BlueprintModel> {
    return this.updateBlueprint(id, { status: BlueprintStatusEnum.INACTIVE });
  }

  /**
   * Activate blueprint
   */
  async activateBlueprint(id: string): Promise<BlueprintModel> {
    return this.updateBlueprint(id, { status: BlueprintStatusEnum.ACTIVE });
  }

  /**
   * Search blueprints
   */
  async searchBlueprints(searchTerm: string): Promise<BlueprintModel[]> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      // Client-side filtering
      const blueprints = await firstValueFrom(this.blueprintRepo.findPublicBlueprints());
      const term = searchTerm.toLowerCase();
      return blueprints.filter(b => b.name.toLowerCase().includes(term) || b.description?.toLowerCase().includes(term));
    } catch (error) {
      this.errorState.set(error instanceof Error ? error.message : 'Failed to search blueprints');
      throw error;
    } finally {
      this.loadingState.set(false);
    }
  }

  /**
   * Clear error state
   */
  clearError(): void {
    this.errorState.set(null);
  }

  /**
   * Clear selection
   */
  clearSelection(): void {
    this.selectedBlueprintState.set(null);
  }
}

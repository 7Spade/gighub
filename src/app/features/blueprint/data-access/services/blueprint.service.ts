/**
 * Blueprint Service
 *
 * Business logic for Blueprint Container management
 * Following vertical slice architecture
 *
 * Uses Angular Signals for reactive state management
 *
 * @module features/blueprint/data-access/services/blueprint.service
 */

import { Injectable, inject, signal, computed } from '@angular/core';
import { AuthContextService } from '@core';
import { firstValueFrom } from 'rxjs';

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
  readonly publishedBlueprints = computed(() => this.blueprints().filter(b => b.status === BlueprintStatusEnum.PUBLISHED));

  readonly draftBlueprints = computed(() => this.blueprints().filter(b => b.status === BlueprintStatusEnum.DRAFT));

  readonly archivedBlueprints = computed(() => this.blueprints().filter(b => b.status === BlueprintStatusEnum.ARCHIVED));

  readonly statistics = computed<BlueprintStatistics>(() => {
    const blueprints = this.blueprints();

    return {
      totalCount: blueprints.length,
      publishedCount: blueprints.filter(b => b.status === BlueprintStatusEnum.PUBLISHED).length,
      draftCount: blueprints.filter(b => b.status === BlueprintStatusEnum.DRAFT).length,
      archivedCount: blueprints.filter(b => b.status === BlueprintStatusEnum.ARCHIVED).length
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
   * Load public blueprints (marketplace)
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
   * Create new blueprint (simplified - structure is optional)
   */
  async createBlueprint(request: CreateBlueprintRequest): Promise<BlueprintModel> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      // Build the insert object - structure is now optional
      const blueprintInsert = {
        name: request.name,
        description: request.description,
        category: request.category,
        visibility: request.visibility || 'hidden',
        ownerId: request.ownerId,
        ownerType: request.ownerType,
        tags: request.tags
      };

      const newBlueprint = await firstValueFrom(this.blueprintRepo.create(blueprintInsert));

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
   * Delete blueprint
   */
  async deleteBlueprint(id: string): Promise<void> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      await firstValueFrom(this.blueprintRepo.delete(id));

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
   * Publish blueprint
   */
  async publishBlueprint(id: string): Promise<BlueprintModel> {
    return this.updateBlueprint(id, { status: BlueprintStatusEnum.PUBLISHED });
  }

  /**
   * Archive blueprint
   */
  async archiveBlueprint(id: string): Promise<BlueprintModel> {
    return this.updateBlueprint(id, { status: BlueprintStatusEnum.ARCHIVED });
  }

  /**
   * Search blueprints
   *
   * Note: Full-text search is not yet implemented in the repository.
   * This method falls back to client-side filtering of public blueprints.
   */
  async searchBlueprints(searchTerm: string): Promise<BlueprintModel[]> {
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      // Fallback to client-side filtering until repository search is implemented
      const blueprints = await firstValueFrom(this.blueprintRepo.findPublicBlueprints());
      const term = searchTerm.toLowerCase();
      return blueprints.filter(
        b =>
          b.name.toLowerCase().includes(term) ||
          b.description?.toLowerCase().includes(term) ||
          b.category?.toLowerCase().includes(term) ||
          b.tags?.some(tag => tag.toLowerCase().includes(term))
      );
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

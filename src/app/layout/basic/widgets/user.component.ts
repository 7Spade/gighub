import { ChangeDetectionStrategy, Component, inject, computed } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { AuthContextService, ContextType, SupabaseAuthService } from '@core';
import { I18nPipe, SettingsService, User } from '@delon/theme';
import { User as SupabaseUser } from '@supabase/supabase-js';
import { NzAvatarModule } from 'ng-zorro-antd/avatar';
import { NzDropDownModule } from 'ng-zorro-antd/dropdown';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMenuModule } from 'ng-zorro-antd/menu';

@Component({
  selector: 'header-user',
  template: `
    <div class="alain-default__nav-item d-flex align-items-center px-sm" nz-dropdown nzPlacement="bottomRight" [nzDropdownMenu]="userMenu">
      <nz-avatar [nzSrc]="user().avatar" nzSize="small" class="mr-sm" />
      {{ user().name }}
    </div>
    <nz-dropdown-menu #userMenu="nzDropdownMenu">
      <div nz-menu class="width-sm">
        <div nz-menu-item routerLink="/pro/account/center">
          <i nz-icon nzType="user" class="mr-sm"></i>
          {{ 'menu.account.center' | i18n }}
        </div>
        <div nz-menu-item routerLink="/pro/account/settings">
          <i nz-icon nzType="setting" class="mr-sm"></i>
          {{ 'menu.account.settings' | i18n }}
        </div>
        <div nz-menu-item routerLink="/exception/trigger">
          <i nz-icon nzType="close-circle" class="mr-sm"></i>
          {{ 'menu.account.trigger' | i18n }}
        </div>
        <li nz-menu-divider></li>
        <div nz-menu-item (click)="logout()">
          <i nz-icon nzType="logout" class="mr-sm"></i>
          {{ 'menu.account.logout' | i18n }}
        </div>
      </div>
    </nz-dropdown-menu>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, NzDropDownModule, NzMenuModule, NzIconModule, I18nPipe, NzAvatarModule]
})
export class HeaderUserComponent {
  private readonly settings = inject(SettingsService);
  private readonly router = inject(Router);
  private readonly authContext = inject(AuthContextService);
  private readonly supabaseAuth = inject(SupabaseAuthService);

  // 從 Supabase 獲取當前用戶
  private readonly supabaseUser = toSignal<SupabaseUser | null>(this.supabaseAuth.currentUser$, { initialValue: null });

  // 根據當前工作區上下文計算用戶信息（現代化：使用 computed 依賴工作區上下文）
  readonly user = computed<User>(() => {
    const supabaseUser = this.supabaseUser();
    const contextType = this.authContext.contextType();
    const contextId = this.authContext.contextId();
    const contextLabel = this.authContext.contextLabel();

    // 根據工作區上下文返回對應的用戶信息
    switch (contextType) {
      case ContextType.USER:
        // 個人帳戶：使用 Supabase 用戶信息
        if (!supabaseUser) {
          return this.settings.user;
        }
        const metadata = supabaseUser.user_metadata || {};
        const email = supabaseUser.email || '';
        return {
          name: metadata['full_name'] || metadata['name'] || email.split('@')[0] || 'User',
          email: email,
          avatar: metadata['avatar_url'] || metadata['avatar'] || './assets/tmp/img/avatar.jpg'
        };

      case ContextType.ORGANIZATION:
        // 組織上下文：顯示組織信息
        const org = this.authContext.getOrganizationById(contextId || '');
        return {
          name: contextLabel || (org?.name as string) || '組織',
          email: '',
          avatar: org?.avatar_url || './assets/tmp/img/avatar.jpg'
        };

      case ContextType.TEAM:
        // 團隊上下文：顯示團隊信息
        const team = this.authContext.getTeamById(contextId || '');
        return {
          name: contextLabel || (team?.name as string) || '團隊',
          email: '',
          avatar: './assets/tmp/img/avatar.jpg'
        };

      case ContextType.BOT:
        // 機器人上下文
        return {
          name: contextLabel || '機器人',
          email: '',
          avatar: './assets/tmp/img/avatar.jpg'
        };

      default:
        // 預設使用 Supabase 用戶信息
        if (!supabaseUser) {
          return this.settings.user;
        }
        const defaultMetadata = supabaseUser.user_metadata || {};
        const defaultEmail = supabaseUser.email || '';
        return {
          name: defaultMetadata['full_name'] || defaultMetadata['name'] || defaultEmail.split('@')[0] || 'User',
          email: defaultEmail,
          avatar: defaultMetadata['avatar_url'] || defaultMetadata['avatar'] || './assets/tmp/img/avatar.jpg'
        };
    }
  });

  async logout(): Promise<void> {
    await this.supabaseAuth.signOut();
    this.router.navigateByUrl('/passport/login');
  }
}

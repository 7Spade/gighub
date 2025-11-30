import { Component, inject, computed, effect } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink, RouterOutlet } from '@angular/router';
import { SupabaseAuthService, AuthContextService, ContextType } from '@core';
import { I18nPipe, ModalHelper, SettingsService, User } from '@delon/theme';
import { LayoutDefaultModule, LayoutDefaultOptions } from '@delon/theme/layout-default';
import { SettingDrawerModule } from '@delon/theme/setting-drawer';
import { ThemeBtnComponent } from '@delon/theme/theme-btn';
import { environment } from '@env/environment';
import { User as SupabaseUser } from '@supabase/supabase-js';
import { NzAvatarModule } from 'ng-zorro-antd/avatar';
import { NzDropDownModule } from 'ng-zorro-antd/dropdown';
import { NzIconModule } from 'ng-zorro-antd/icon';
import { NzMenuModule } from 'ng-zorro-antd/menu';

import { HeaderClearStorageComponent } from './widgets/clear-storage.component';
import { HeaderContextSwitcherComponent } from './widgets/context-switcher.component';
import { HeaderFullScreenComponent } from './widgets/fullscreen.component';
import { HeaderI18nComponent } from './widgets/i18n.component';
import { HeaderIconComponent } from './widgets/icon.component';
import { HeaderNotifyComponent } from './widgets/notify.component';
import { HeaderRTLComponent } from './widgets/rtl.component';
import { HeaderSearchComponent } from './widgets/search.component';
import { HeaderTaskComponent } from './widgets/task.component';
import { HeaderUserComponent } from './widgets/user.component';
import { CreateOrganizationComponent } from '../../routes/account/create-organization/create-organization.component';

@Component({
  selector: 'layout-basic',
  template: `
    <layout-default [options]="options" [asideUser]="asideUserTpl" [content]="contentTpl" [customError]="null">
      <layout-default-header-item direction="left">
        <a layout-default-header-item-trigger href="//github.com/ng-alain/ng-alain" target="_blank">
          <i nz-icon nzType="github"></i>
        </a>
      </layout-default-header-item>
      <layout-default-header-item direction="left" hidden="mobile">
        <a layout-default-header-item-trigger routerLink="/passport/lock">
          <i nz-icon nzType="lock"></i>
        </a>
      </layout-default-header-item>
      <layout-default-header-item direction="left" hidden="pc">
        <div layout-default-header-item-trigger (click)="searchToggleStatus = !searchToggleStatus">
          <i nz-icon nzType="search"></i>
        </div>
      </layout-default-header-item>
      <layout-default-header-item direction="middle">
        <header-search class="alain-default__search" [(toggleChange)]="searchToggleStatus" />
      </layout-default-header-item>
      <layout-default-header-item direction="right">
        <header-notify />
      </layout-default-header-item>
      <layout-default-header-item direction="right" hidden="mobile">
        <header-task />
      </layout-default-header-item>
      <layout-default-header-item direction="right" hidden="mobile">
        <header-icon />
      </layout-default-header-item>
      <layout-default-header-item direction="right" hidden="mobile">
        <div layout-default-header-item-trigger nz-dropdown [nzDropdownMenu]="settingsMenu" nzTrigger="click" nzPlacement="bottomRight">
          <i nz-icon nzType="setting"></i>
        </div>
        <nz-dropdown-menu #settingsMenu="nzDropdownMenu">
          <div nz-menu style="width: 200px;">
            <div nz-menu-item>
              <header-rtl />
            </div>
            <div nz-menu-item>
              <header-fullscreen />
            </div>
            <div nz-menu-item>
              <header-clear-storage />
            </div>
            <div nz-menu-item>
              <header-i18n />
            </div>
          </div>
        </nz-dropdown-menu>
      </layout-default-header-item>
      <layout-default-header-item direction="right">
        <header-user />
      </layout-default-header-item>
      <ng-template #asideUserTpl>
        <div nz-dropdown nzTrigger="click" [nzDropdownMenu]="userMenu" class="alain-default__aside-user">
          <nz-avatar class="alain-default__aside-user-avatar" [nzSrc]="user().avatar" />
          <div class="alain-default__aside-user-info">
            <strong>{{ user().name }}</strong>
            <p class="mb0">{{ user().email }}</p>
          </div>
        </div>
        <nz-dropdown-menu #userMenu="nzDropdownMenu">
          <ul nz-menu>
            <!-- 上下文切換器區域 -->
            <li nz-menu-item [nzDisabled]="true" style="cursor: default; opacity: 1; background: transparent;">
              <div style="font-weight: 600; color: rgba(0, 0, 0, 0.85); margin-bottom: 4px;"> 切換工作區 </div>
            </li>
            <li style="padding: 0;">
              <header-context-switcher />
            </li>
            <li nz-menu-divider></li>

            <li nz-menu-item (click)="openCreateOrganization()">
              <i nz-icon nzType="plus-circle" class="mr-sm"></i>
              <span>建立組織</span>
            </li>
          </ul>
        </nz-dropdown-menu>
      </ng-template>
      <ng-template #contentTpl>
        <router-outlet />
      </ng-template>
    </layout-default>
    @if (showSettingDrawer) {
      <setting-drawer />
    }
    <theme-btn />
  `,
  imports: [
    RouterOutlet,
    RouterLink,
    LayoutDefaultModule,
    NzIconModule,
    NzMenuModule,
    NzDropDownModule,
    NzAvatarModule,
    SettingDrawerModule,
    ThemeBtnComponent,
    HeaderSearchComponent,
    HeaderNotifyComponent,
    HeaderTaskComponent,
    HeaderIconComponent,
    HeaderRTLComponent,
    HeaderI18nComponent,
    HeaderClearStorageComponent,
    HeaderFullScreenComponent,
    HeaderUserComponent,
    HeaderContextSwitcherComponent
  ]
})
export class LayoutBasicComponent {
  private readonly settings = inject(SettingsService);
  private readonly supabaseAuth = inject(SupabaseAuthService);
  private readonly modal = inject(ModalHelper);
  private readonly authContext = inject(AuthContextService);

  options: LayoutDefaultOptions = {
    logoExpanded: `./assets/logo-full.svg`,
    logoCollapsed: `./assets/logo.svg`
  };
  searchToggleStatus = false;
  showSettingDrawer = !environment.production;

  // 從 Supabase 獲取當前用戶
  private readonly supabaseUser = toSignal<SupabaseUser | null>(this.supabaseAuth.currentUser$, { initialValue: null });

  // 根據當前工作區上下文計算用戶信息（現代化：使用 computed 依賴工作區上下文）
  readonly user = computed<User>(() => {
    const supabaseUser = this.supabaseUser();
    const contextType = this.authContext.contextType();
    const contextId = this.authContext.contextId();
    const contextLabel = this.authContext.contextLabel();
    const contextIcon = this.authContext.contextIcon();

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

  constructor() {
    // 監聯上下文變化並更新菜單（AuthContextService 內部會自動同步菜單）
    effect(() => {
      const contextType = this.authContext.contextType();
      const contextId = this.authContext.contextId();

      // 日誌記錄上下文變化
      console.log('[LayoutBasicComponent] Context changed:', { contextType, contextId });
    });
  }

  /**
   * 打開建立組織模態框
   * Open create organization modal
   */
  openCreateOrganization(): void {
    this.modal.create(CreateOrganizationComponent, {}, { size: 'md' }).subscribe(result => {
      if (result) {
        console.log('組織創建成功:', result);
        // 組織創建成功後，重新載入工作區資料
        this.authContext.reloadWorkspaceData();
      }
    });
  }
}

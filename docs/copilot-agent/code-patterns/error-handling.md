# 🚨 錯誤處理模式

> 統一的錯誤處理策略

---

## Store 層錯誤處理

### 基本模式

```typescript
@Injectable()
export class FeatureStore {
  private readonly _state = signal<FeatureState>(initialState);
  
  readonly error = computed(() => this._state().error);

  async loadItems(): Promise<void> {
    this._state.update(s => ({ ...s, loading: true, error: null }));
    try {
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items, loading: false }));
    } catch (error) {
      this._handleError(error, '載入資料失敗');
    }
  }

  private _handleError(error: unknown, defaultMessage: string): void {
    const message = this._extractErrorMessage(error, defaultMessage);
    this._state.update(s => ({
      ...s,
      loading: false,
      error: message,
    }));
    console.error(`[FeatureStore] Error:`, error);
  }

  private _extractErrorMessage(error: unknown, defaultMessage: string): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    if (error && typeof error === 'object' && 'message' in error) {
      return String(error.message);
    }
    return defaultMessage;
  }

  clearError(): void {
    this._state.update(s => ({ ...s, error: null }));
  }
}
```

### 帶重試的錯誤處理

```typescript
async loadItemsWithRetry(maxRetries = 3): Promise<void> {
  let lastError: unknown;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      this._state.update(s => ({ ...s, loading: true, error: null }));
      const items = await this.repository.findAll();
      this._state.update(s => ({ ...s, items, loading: false }));
      return;
    } catch (error) {
      lastError = error;
      if (attempt < maxRetries) {
        // 指數退避
        await this._delay(Math.pow(2, attempt) * 1000);
      }
    }
  }
  
  this._handleError(lastError, '載入資料失敗，請稍後重試');
}

private _delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

## 元件層錯誤顯示

### 使用 NZ-ALERT

```html
@if (store.error()) {
  <nz-alert
    nzType="error"
    [nzMessage]="store.error()"
    nzShowIcon
    nzCloseable
    (nzOnClose)="store.clearError()"
  />
}
```

### 帶重試按鈕

```html
@if (store.error()) {
  <nz-result nzStatus="error" [nzTitle]="store.error()">
    <div nz-result-extra>
      <button nz-button nzType="primary" (click)="store.loadItems()">
        重試
      </button>
    </div>
  </nz-result>
}
```

### 內嵌錯誤提示

```html
<nz-card>
  @if (store.loading()) {
    <nz-spin />
  } @else if (store.error()) {
    <nz-alert
      nzType="error"
      [nzMessage]="store.error()"
      [nzAction]="retryTpl"
    />
    <ng-template #retryTpl>
      <button nz-button nzSize="small" (click)="store.loadItems()">重試</button>
    </ng-template>
  } @else {
    <!-- 正常內容 -->
  }
</nz-card>
```

---

## 表單驗證錯誤

### 表單驗證

```typescript
@Component({
  // ...
})
export class FeatureFormComponent {
  private readonly fb = inject(FormBuilder);

  form = this.fb.group({
    name: ['', [Validators.required, Validators.maxLength(100)]],
    email: ['', [Validators.required, Validators.email]],
  });

  onSubmit(): void {
    if (this.form.valid) {
      // 提交
    } else {
      this._markAllAsDirty();
    }
  }

  private _markAllAsDirty(): void {
    Object.values(this.form.controls).forEach(control => {
      control.markAsDirty();
      control.updateValueAndValidity();
    });
  }
}
```

### 自訂錯誤提示

```html
<nz-form-item>
  <nz-form-label nzRequired>名稱</nz-form-label>
  <nz-form-control [nzErrorTip]="nameErrorTpl">
    <input nz-input formControlName="name" />
  </nz-form-control>
  <ng-template #nameErrorTpl let-control>
    @if (control.hasError('required')) {
      請輸入名稱
    } @else if (control.hasError('maxlength')) {
      名稱不能超過 100 個字元
    }
  </ng-template>
</nz-form-item>
```

---

## 全域錯誤處理

### HTTP 攔截器

```typescript
// core/net/default.interceptor.ts
export const defaultInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      let message = '請求失敗';

      switch (error.status) {
        case 401:
          message = '未授權，請重新登入';
          // 導向登入頁
          break;
        case 403:
          message = '無權限存取';
          break;
        case 404:
          message = '資源不存在';
          break;
        case 500:
          message = '伺服器錯誤';
          break;
        default:
          message = error.message || '未知錯誤';
      }

      // 顯示全域錯誤提示
      inject(NzMessageService).error(message);

      return throwError(() => new Error(message));
    })
  );
};
```

---

## 錯誤碼對照表

| 錯誤碼 | 說明 | 前端處理 |
|--------|------|----------|
| `PGRST116` | Supabase 找不到資料 | 顯示 "資料不存在" |
| `23505` | 唯一約束違反 | 顯示 "資料已存在" |
| `23503` | 外鍵約束違反 | 顯示 "關聯資料不存在" |
| `42501` | 權限不足 | 顯示 "無權限執行此操作" |

---

**最後更新**: 2025-11-27

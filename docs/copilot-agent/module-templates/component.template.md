# 📦 Component 範本

> Angular Standalone Component 範本

---

## Shell 元件 (Smart Component)

### 基本範本

```typescript
// features/{feature}/shell/{feature}-shell/{feature}-shell.component.ts
import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';

import { {Feature}Store } from '../../data-access/stores/{feature}.store';
import { {Feature}ListComponent } from '../../ui/{feature}-list/{feature}-list.component';

@Component({
  selector: 'app-{feature}-shell',
  standalone: true,
  imports: [...SHARED_IMPORTS, {Feature}ListComponent],
  providers: [{Feature}Store],
  templateUrl: './{feature}-shell.component.html',
  styleUrl: './{feature}-shell.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class {Feature}ShellComponent implements OnInit {
  protected readonly store = inject({Feature}Store);

  ngOnInit(): void {
    this.store.loadItems();
  }

  protected onSelect(id: string): void {
    this.store.selectItem(id);
  }

  protected async onDelete(id: string): Promise<void> {
    await this.store.deleteItem(id);
  }

  protected async onCreate(): Promise<void> {
    // 開啟新增對話框
  }
}
```

### 模板範本

```html
<!-- features/{feature}/shell/{feature}-shell/{feature}-shell.component.html -->
<page-header [title]="'{Feature} 管理'">
  <button nz-button nzType="primary" (click)="onCreate()">
    <span nz-icon nzType="plus"></span>
    新增
  </button>
</page-header>

<nz-card>
  @if (store.loading()) {
    <nz-spin nzTip="載入中...">
      <div class="loading-content"></div>
    </nz-spin>
  } @else if (store.error()) {
    <nz-alert
      nzType="error"
      [nzMessage]="store.error()"
      nzShowIcon
      [nzAction]="retryTpl"
    />
    <ng-template #retryTpl>
      <button nz-button nzSize="small" (click)="store.loadItems()">重試</button>
    </ng-template>
  } @else {
    <app-{feature}-list
      [items]="store.items()"
      [selectedId]="store.selectedId()"
      (select)="onSelect($event)"
      (delete)="onDelete($event)"
    />
  }
</nz-card>
```

### 樣式範本

```less
// features/{feature}/shell/{feature}-shell/{feature}-shell.component.less
.loading-content {
  min-height: 200px;
}
```

---

## UI 元件 (Presentational Component)

### 列表元件

```typescript
// features/{feature}/ui/{feature}-list/{feature}-list.component.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';

import { {Feature} } from '../../domain/models/{feature}.model';
import { {FEATURE}_STATUS_LABELS } from '../../domain/enums/{feature}-status.enum';

@Component({
  selector: 'app-{feature}-list',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  templateUrl: './{feature}-list.component.html',
  styleUrl: './{feature}-list.component.less',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class {Feature}ListComponent {
  // Inputs
  readonly items = input<{Feature}[]>([]);
  readonly selectedId = input<string | null>(null);
  readonly loading = input(false);

  // Outputs
  readonly select = output<string>();
  readonly delete = output<string>();
  readonly edit = output<string>();

  // 常數
  protected readonly statusLabels = {FEATURE}_STATUS_LABELS;

  // 方法
  protected isSelected(id: string): boolean {
    return this.selectedId() === id;
  }

  protected onSelect(id: string): void {
    this.select.emit(id);
  }

  protected onEdit(id: string, event: Event): void {
    event.stopPropagation();
    this.edit.emit(id);
  }

  protected onDelete(id: string, event: Event): void {
    event.stopPropagation();
    this.delete.emit(id);
  }
}
```

### 列表模板

```html
<!-- features/{feature}/ui/{feature}-list/{feature}-list.component.html -->
@if (items().length === 0) {
  <nz-empty nzNotFoundContent="暫無資料" />
} @else {
  <nz-table
    [nzData]="items()"
    [nzLoading]="loading()"
    nzSize="middle"
    [nzShowPagination]="items().length > 10"
  >
    <thead>
      <tr>
        <th>名稱</th>
        <th nzWidth="100px">狀態</th>
        <th nzWidth="180px">建立時間</th>
        <th nzWidth="120px">操作</th>
      </tr>
    </thead>
    <tbody>
      @for (item of items(); track item.id) {
        <tr
          [class.selected]="isSelected(item.id)"
          (click)="onSelect(item.id)"
        >
          <td>{{ item.name }}</td>
          <td>
            <nz-tag [nzColor]="item.status === 'active' ? 'green' : 'default'">
              {{ statusLabels[item.status] }}
            </nz-tag>
          </td>
          <td>{{ item.createdAt | date:'yyyy-MM-dd HH:mm' }}</td>
          <td>
            <button
              nz-button
              nzType="link"
              nzSize="small"
              (click)="onEdit(item.id, $event)"
            >
              編輯
            </button>
            <button
              nz-button
              nzType="link"
              nzDanger
              nzSize="small"
              nz-popconfirm
              nzPopconfirmTitle="確定要刪除嗎？"
              (nzOnConfirm)="onDelete(item.id, $event)"
            >
              刪除
            </button>
          </td>
        </tr>
      }
    </tbody>
  </nz-table>
}
```

### 卡片元件

```typescript
// features/{feature}/ui/{feature}-card/{feature}-card.component.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { SHARED_IMPORTS } from '@shared';

import { {Feature} } from '../../domain/models/{feature}.model';

@Component({
  selector: 'app-{feature}-card',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  template: `
    <nz-card
      [nzTitle]="item().name"
      [nzExtra]="extraTpl"
      [class.selected]="selected()"
      (click)="select.emit(item().id)"
    >
      <p>{{ item().description }}</p>
      <nz-tag [nzColor]="item().status === 'active' ? 'green' : 'default'">
        {{ item().status }}
      </nz-tag>
    </nz-card>

    <ng-template #extraTpl>
      <button nz-button nzType="text" nzSize="small" (click)="edit.emit(item().id)">
        <span nz-icon nzType="edit"></span>
      </button>
    </ng-template>
  `,
  styles: [`
    nz-card {
      cursor: pointer;
      transition: all 0.3s;

      &:hover {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      }

      &.selected {
        border-color: #1890ff;
      }
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class {Feature}CardComponent {
  readonly item = input.required<{Feature}>();
  readonly selected = input(false);

  readonly select = output<string>();
  readonly edit = output<string>();
}
```

---

## Dialog 元件

### 對話框元件

```typescript
// features/{feature}/shell/dialogs/{feature}-dialog/{feature}-dialog.component.ts
import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { NZ_MODAL_DATA, NzModalRef } from 'ng-zorro-antd/modal';
import { SHARED_IMPORTS } from '@shared';

import { {Feature} } from '../../../domain/models/{feature}.model';
import { {Feature}Status } from '../../../domain/enums/{feature}-status.enum';

interface DialogData {
  mode: 'create' | 'edit';
  item?: {Feature};
}

@Component({
  selector: 'app-{feature}-dialog',
  standalone: true,
  imports: [...SHARED_IMPORTS],
  templateUrl: './{feature}-dialog.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class {Feature}DialogComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly modalRef = inject(NzModalRef);
  private readonly data = inject<DialogData>(NZ_MODAL_DATA);

  protected readonly form = this.fb.group({
    name: ['', [Validators.required, Validators.maxLength(100)]],
    description: ['', [Validators.maxLength(500)]],
    status: [{Feature}Status.DRAFT],
  });

  protected readonly statusOptions = Object.values({Feature}Status);
  protected readonly isEditMode = this.data.mode === 'edit';

  ngOnInit(): void {
    if (this.isEditMode && this.data.item) {
      this.form.patchValue(this.data.item);
    }
  }

  protected onSubmit(): void {
    if (this.form.valid) {
      this.modalRef.close(this.form.value);
    } else {
      Object.values(this.form.controls).forEach(control => {
        control.markAsDirty();
        control.updateValueAndValidity();
      });
    }
  }

  protected onCancel(): void {
    this.modalRef.destroy();
  }
}
```

### 對話框模板

```html
<!-- features/{feature}/shell/dialogs/{feature}-dialog/{feature}-dialog.component.html -->
<form nz-form [formGroup]="form" nzLayout="vertical">
  <nz-form-item>
    <nz-form-label nzRequired>名稱</nz-form-label>
    <nz-form-control nzErrorTip="請輸入名稱">
      <input nz-input formControlName="name" placeholder="請輸入名稱" />
    </nz-form-control>
  </nz-form-item>

  <nz-form-item>
    <nz-form-label>描述</nz-form-label>
    <nz-form-control>
      <textarea
        nz-input
        formControlName="description"
        placeholder="請輸入描述"
        [nzAutosize]="{ minRows: 3, maxRows: 6 }"
      ></textarea>
    </nz-form-control>
  </nz-form-item>

  <nz-form-item>
    <nz-form-label>狀態</nz-form-label>
    <nz-form-control>
      <nz-select formControlName="status">
        @for (status of statusOptions; track status) {
          <nz-option [nzValue]="status" [nzLabel]="status" />
        }
      </nz-select>
    </nz-form-control>
  </nz-form-item>

  <div class="dialog-footer">
    <button nz-button nzType="default" (click)="onCancel()">取消</button>
    <button nz-button nzType="primary" (click)="onSubmit()">
      {{ isEditMode ? '更新' : '建立' }}
    </button>
  </div>
</form>
```

---

## 常用模式

### 使用 @delon/abc ST 元件

```typescript
import { STColumn, STComponent } from '@delon/abc/st';

@Component({
  // ...
  template: `
    <st [data]="items()" [columns]="columns" />
  `,
})
export class {Feature}ListComponent {
  readonly items = input<{Feature}[]>([]);

  readonly columns: STColumn[] = [
    { title: '名稱', index: 'name' },
    { title: '狀態', index: 'status', type: 'tag', tag: {
      draft: { text: '草稿', color: 'default' },
      active: { text: '進行中', color: 'green' },
    }},
    { title: '建立時間', index: 'createdAt', type: 'date' },
    {
      title: '操作',
      buttons: [
        { text: '編輯', click: item => this.edit.emit(item.id) },
        { text: '刪除', type: 'del', click: item => this.delete.emit(item.id) },
      ],
    },
  ];

  readonly edit = output<string>();
  readonly delete = output<string>();
}
```

---

**最後更新**: 2025-11-27

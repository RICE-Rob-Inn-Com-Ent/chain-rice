import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'ui-click',
  standalone: true,
  template: `
    <ng-container [ngSwitch]="tag">
      <button
        *ngSwitchCase="'button'"
        [attr.type]="type"
        [disabled]="disabled"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </button>
      <a
        *ngSwitchCase="'a'"
        [href]="url"
        [target]="target"
        [class]="computedClasses"
        (click)="clicked()"
        [attr.title]="title"
      >
        <ng-content></ng-content>
      </a>
    </ng-container>
  `,
})
export class ClickComponent {
  @Input() tag: 'button' | 'a' = 'button';
  @Input() type: 'button' | 'submit' | 'reset' = 'button';
  @Input() disabled = false;
  @Input() styleClass = '';
  @Input() className = '';
  @Input() url?: string;
  @Input() target?: string;
  @Input() title?: string;
  @Output() click = new EventEmitter<void>();

  get computedClasses(): string {
    const base = this.getTagClasses(this.tag, this.type);
    return `${base} ${this.styleClass} ${this.className}`.trim();
  }

  clicked(): void {
    this.click.emit();
  }

  private getTagClasses(tag: string, type?: string): string {
    if (tag === 'button') {
      switch (type) {
        case 'submit':
          return 'w-full px-4 py-3 bg-blue-600 text-white font-semibold rounded-lg shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed';
        case 'reset':
          return 'px-4 py-2 bg-gray-500 text-white font-medium rounded-md shadow-sm hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200 active:scale-95';
        default:
          return 'px-4 py-2 bg-gray-100 text-gray-700 font-medium rounded-md shadow-sm hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200 active:scale-95 border border-gray-300';
      }
    }
    if (tag === 'a') {
      return 'inline-flex items-center px-4 py-2 text-blue-600 font-medium rounded-md hover:text-blue-700 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 underline decoration-2 underline-offset-2';
    }
    return '';
  }
}

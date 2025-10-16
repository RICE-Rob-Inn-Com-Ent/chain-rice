import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

type Tag =
  | 'div'
  | 'section'
  | 'article'
  | 'main'
  | 'aside'
  | 'nav'
  | 'header'
  | 'footer'
  | 'table'
  | 'thead'
  | 'tbody'
  | 'tfoot'
  | 'tr'
  | 'th'
  | 'td'
  | 'caption'
  | 'col'
  | 'colgroup'
  | 'figure'
  | 'figcaption'
  | 'details'
  | 'summary'
  | 'dialog'
  | 'span';

@Component({
  selector: 'ui-container',
  standalone: true,
  imports: [CommonModule],
  template: `
    <ng-container [ngSwitch]="tag">
      <div
        *ngSwitchCase="'div'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </div>
      <section
        *ngSwitchCase="'section'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </section>
      <article
        *ngSwitchCase="'article'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </article>
      <main
        *ngSwitchCase="'main'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </main>
      <aside
        *ngSwitchCase="'aside'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </aside>
      <nav
        *ngSwitchCase="'nav'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </nav>
      <header
        *ngSwitchCase="'header'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </header>
      <footer
        *ngSwitchCase="'footer'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </footer>
      <table
        *ngSwitchCase="'table'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </table>
      <thead
        *ngSwitchCase="'thead'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </thead>
      <tbody
        *ngSwitchCase="'tbody'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </tbody>
      <tfoot
        *ngSwitchCase="'tfoot'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </tfoot>
      <tr
        *ngSwitchCase="'tr'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </tr>
      <th
        *ngSwitchCase="'th'"
        [id]="id"
        [class]="computedClasses"
        [attr.colspan]="colSpan"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </th>
      <td
        *ngSwitchCase="'td'"
        [id]="id"
        [class]="computedClasses"
        [attr.colspan]="colSpan"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </td>
      <caption
        *ngSwitchCase="'caption'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </caption>
      <figure
        *ngSwitchCase="'figure'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </figure>
      <figcaption
        *ngSwitchCase="'figcaption'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </figcaption>
      <details
        *ngSwitchCase="'details'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </details>
      <summary
        *ngSwitchCase="'summary'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </summary>
      <dialog
        *ngSwitchCase="'dialog'"
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </dialog>
      <span
        *ngSwitchDefault
        [id]="id"
        [class]="computedClasses"
        (click)="clicked()"
      >
        <ng-content></ng-content>
      </span>
    </ng-container>
  `,
})
export class ContainerComponent {
  @Input() tag: Tag = 'div';
  @Input() id?: string;
  @Input() styleClass = '';
  @Input() className = '';
  @Input() colSpan?: number;
  @Output() click = new EventEmitter<void>();

  get computedClasses(): string {
    const base = this.getTagClasses(this.tag);
    return `${base} ${this.styleClass} ${this.className}`.trim();
  }

  clicked(): void {
    this.click.emit();
  }

  private getTagClasses(tag: Tag): string {
    switch (tag) {
      case 'div':
        return 'max-w-7xl mx-auto px-4 sm:px-6 lg:px-8';
      case 'section':
        return 'py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto';
      case 'article':
        return 'max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6';
      case 'main':
        return 'flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8';
      case 'aside':
        return 'w-64 bg-gray-50 border-r border-gray-200 p-4';
      case 'nav':
        return 'bg-white shadow-sm border-b border-gray-200 px-4 sm:px-6 lg:px-8';
      case 'header':
        return 'bg-white shadow-sm border-b border-gray-200 px-4 sm:px-6 lg:px-8 py-4';
      case 'footer':
        return 'bg-gray-50 border-t border-gray-200 px-4 sm:px-6 lg:px-8 py-8';
      case 'table':
        return 'min-w-full divide-y divide-gray-200 bg-white rounded-lg shadow-sm border border-gray-200';
      case 'thead':
        return 'bg-gray-50';
      case 'tbody':
        return 'bg-white divide-y divide-gray-200';
      case 'tfoot':
        return 'bg-gray-50';
      case 'tr':
        return 'hover:bg-gray-50 transition-colors duration-150';
      case 'th':
        return 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider';
      case 'td':
        return 'px-6 py-4 whitespace-nowrap text-sm text-gray-900';
      case 'caption':
        return 'px-6 py-2 text-sm text-gray-600 bg-gray-50 border-t border-gray-200';
      case 'figure':
        return 'max-w-lg mx-auto bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden';
      case 'figcaption':
        return 'px-4 py-3 text-sm text-gray-600 bg-gray-50 border-t border-gray-200';
      case 'details':
        return 'bg-white rounded-lg shadow-sm border border-gray-200 p-4';
      case 'summary':
        return 'cursor-pointer font-medium text-gray-900 hover:text-blue-600 transition-colors duration-150';
      case 'dialog':
        return 'bg-white rounded-lg shadow-xl border border-gray-200 p-6 max-w-md mx-auto';
      default:
        return 'max-w-7xl mx-auto px-4 sm:px-6 lg:px-8';
    }
  }
}

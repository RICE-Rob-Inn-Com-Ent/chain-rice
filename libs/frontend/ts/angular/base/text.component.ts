import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

type Tag =
  | 'p'
  | 'span'
  | 'strong'
  | 'em'
  | 'small'
  | 'mark'
  | 'code'
  | 'pre'
  | 'blockquote'
  | 'time'
  | 'u'
  | 'i'
  | 'b'
  | 's'
  | 'sub'
  | 'sup'
  | 'h1'
  | 'h2'
  | 'h3'
  | 'h4'
  | 'h5'
  | 'h6'
  | 'q'
  | 'cite'
  | 'abbr'
  | 'del'
  | 'ins'
  | 'div';

@Component({
  selector: 'ui-text',
  standalone: true,
  imports: [CommonModule],
  template: `
    <ng-container [ngSwitch]="tag">
      <h1 *ngSwitchCase="'h1'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h1>
      <h2 *ngSwitchCase="'h2'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h2>
      <h3 *ngSwitchCase="'h3'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h3>
      <h4 *ngSwitchCase="'h4'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h4>
      <h5 *ngSwitchCase="'h5'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h5>
      <h6 *ngSwitchCase="'h6'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </h6>
      <p *ngSwitchCase="'p'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </p>
      <span *ngSwitchCase="'span'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </span>
      <strong *ngSwitchCase="'strong'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </strong>
      <em *ngSwitchCase="'em'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </em>
      <small *ngSwitchCase="'small'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </small>
      <mark *ngSwitchCase="'mark'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </mark>
      <code *ngSwitchCase="'code'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </code>
      <pre *ngSwitchCase="'pre'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </pre>
      <blockquote
        *ngSwitchCase="'blockquote'"
        [id]="id"
        [class]="computedClasses"
      >
        <ng-content></ng-content>
      </blockquote>
      <time *ngSwitchCase="'time'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </time>
      <u *ngSwitchCase="'u'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </u>
      <i *ngSwitchCase="'i'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </i>
      <b *ngSwitchCase="'b'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </b>
      <s *ngSwitchCase="'s'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </s>
      <sub *ngSwitchCase="'sub'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </sub>
      <sup *ngSwitchCase="'sup'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </sup>
      <q *ngSwitchCase="'q'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </q>
      <cite *ngSwitchCase="'cite'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </cite>
      <abbr *ngSwitchCase="'abbr'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </abbr>
      <del *ngSwitchCase="'del'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </del>
      <ins *ngSwitchCase="'ins'" [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </ins>
      <div *ngSwitchDefault [id]="id" [class]="computedClasses">
        <ng-content></ng-content>
      </div>
    </ng-container>
  `,
})
export class TextComponent {
  @Input() tag: Tag = 'p';
  @Input() id?: string;
  @Input() styleClass = '';

  get computedClasses(): string {
    const base = this.getTagClasses(this.tag);
    return `${base} ${this.styleClass}`.trim();
  }

  private getTagClasses(tag: Tag): string {
    switch (tag) {
      case 'h1':
        return 'text-4xl font-bold text-gray-900 leading-tight tracking-tight';
      case 'h2':
        return 'text-3xl font-bold text-gray-900 leading-tight tracking-tight';
      case 'h3':
        return 'text-2xl font-semibold text-gray-900 leading-tight';
      case 'h4':
        return 'text-xl font-semibold text-gray-900 leading-tight';
      case 'h5':
        return 'text-lg font-medium text-gray-900 leading-tight';
      case 'h6':
        return 'text-base font-medium text-gray-900 leading-tight';
      case 'p':
        return 'text-base text-gray-700 leading-relaxed';
      case 'span':
        return 'text-base text-gray-700';
      case 'strong':
        return 'font-bold text-gray-900';
      case 'em':
        return 'italic text-gray-800';
      case 'small':
        return 'text-sm text-gray-600';
      case 'mark':
        return 'bg-yellow-200 text-gray-900 px-1 rounded';
      case 'code':
        return 'bg-gray-100 text-gray-800 px-2 py-1 rounded text-sm font-mono';
      case 'pre':
        return 'bg-gray-100 text-gray-800 p-4 rounded-lg text-sm font-mono overflow-x-auto';
      case 'blockquote':
        return 'border-l-4 border-blue-500 pl-4 italic text-gray-700 text-lg';
      case 'time':
        return 'text-sm text-gray-600 font-mono';
      case 'u':
        return 'underline text-gray-800';
      case 'i':
        return 'italic text-gray-800';
      case 'b':
        return 'font-bold text-gray-900';
      case 's':
        return 'line-through text-gray-600';
      case 'sub':
        return 'text-sm text-gray-600 align-sub';
      case 'sup':
        return 'text-sm text-gray-600 align-super';
      case 'q':
        return 'italic text-gray-700';
      case 'cite':
        return 'italic text-gray-600 text-sm';
      case 'abbr':
        return 'border-b border-dotted border-gray-400 cursor-help';
      case 'del':
        return 'line-through text-gray-500';
      case 'ins':
        return 'underline text-green-700 bg-green-50 px-1 rounded';
      case 'div':
        return 'text-gray-900';
      default:
        return 'text-gray-900';
    }
  }
}

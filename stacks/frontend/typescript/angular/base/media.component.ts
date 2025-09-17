import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

type Tag =
  | 'img'
  | 'video'
  | 'audio'
  | 'canvas'
  | 'svg'
  | 'picture'
  | 'source'
  | 'track'
  | 'iframe'
  | 'embed'
  | 'object';

@Component({
  selector: 'ui-media',
  standalone: true,
  imports: [CommonModule],
  template: `
    <ng-container [ngSwitch]="tag">
      <img *ngSwitchCase="'img'" [src]="src" [alt]="alt" [class]="computedClasses" [width]="width" [height]="height">
      <video *ngSwitchCase="'video'" [src]="src" [controls]="controls" [autoplay]="autoPlay" [loop]="loop" [class]="computedClasses" [width]="width" [height]="height">
        <ng-content></ng-content>
      </video>
      <audio *ngSwitchCase="'audio'" [src]="src" [controls]="controls" [autoplay]="autoPlay" [loop]="loop" [class]="computedClasses">
        <ng-content></ng-content>
      </audio>
      <canvas *ngSwitchCase="'canvas'" [class]="computedClasses" [width]="width" [height]="height">
        <ng-content></ng-content>
      </canvas>
      <svg *ngSwitchCase="'svg'" [class]="computedClasses" [width]="width" [height]="height">
        <ng-content></ng-content>
      </svg>
      <picture *ngSwitchCase="'picture'" [class]="computedClasses">
        <ng-content></ng-content>
      </picture>
      <iframe *ngSwitchCase="'iframe'" [src]="src" [class]="computedClasses" [width]="width" [height]="height" frameborder="0" allowfullscreen>
        <ng-content></ng-content>
      </iframe>
      <embed *ngSwitchCase="'embed'" [src]="src" [class]="computedClasses" [width]="width" [height]="height">
        <ng-content></ng-content>
      </embed>
      <object *ngSwitchCase="'object'" [data]="src" [class]="computedClasses" [width]="width" [height]="height">
        <ng-content></ng-content>
      </object>
    </ng-container>
  `,
})
export class MediaComponent {
  @Input() tag: Tag = 'img';
  @Input() src?: string;
  @Input() alt?: string;
  @Input() controls = false;
  @Input() autoPlay = false;
  @Input() loop = false;
  @Input() styleClass = '';
  @Input() width?: string | number;
  @Input() height?: string | number;

  get computedClasses(): string {
    const base = this.getTagClasses(this.tag);
    return `${base} ${this.styleClass}`.trim();
  }

  private getTagClasses(tag: Tag): string {
    switch (tag) {
      case 'img':
        return 'max-w-full h-auto rounded-lg shadow-sm border border-gray-200 object-cover';
      case 'video':
        return 'max-w-full h-auto rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'audio':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'canvas':
        return 'max-w-full h-auto rounded-lg shadow-sm border border-gray-200 bg-white';
      case 'svg':
        return 'max-w-full h-auto text-gray-600';
      case 'picture':
        return 'block max-w-full h-auto';
      case 'iframe':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'embed':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'object':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      default:
        return 'max-w-full h-auto';
    }
  }
}

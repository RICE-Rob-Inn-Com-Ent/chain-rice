import React from 'react';

export interface MediaInterface {
  tag?:
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
  src?: string;
  alt?: string;
  controls?: boolean;
  autoPlay?: boolean;
  loop?: boolean;
  style?: {
    className?: string;
    width?: string | number;
    height?: string | number;
    initial?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    animate?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    exit?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    transition?: {
      duration: number;
    };
  };
  children?: React.ReactNode;
}

export const Media: React.FC<MediaInterface> = ({
  tag = 'img',
  src,
  alt,
  controls,
  autoPlay,
  loop,
  style,
  children,
  ...props
}) => {
  const getTagClasses = (tag: string) => {
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
      case 'source':
        return '';
      case 'track':
        return '';
      case 'iframe':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'embed':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      case 'object':
        return 'w-full rounded-lg shadow-sm border border-gray-200 bg-gray-100';
      default:
        return 'max-w-full h-auto';
    }
  };

  const baseClasses = getTagClasses(tag);
  const mediaClasses = `${baseClasses} ${style?.className || ''}`;

  const Component = tag as React.ElementType;

  if (tag === 'img') {
    return (
      <img
        src={src}
        alt={alt}
        className={mediaClasses}
        width={style?.width}
        height={style?.height}
        {...props}
      />
    );
  }

  if (tag === 'video') {
    return (
      <video
        src={src}
        controls={controls}
        autoPlay={autoPlay}
        loop={loop}
        className={mediaClasses}
        width={style?.width}
        height={style?.height}
        {...props}
      >
        {children}
      </video>
    );
  }

  if (tag === 'audio') {
    return (
      <audio
        src={src}
        controls={controls}
        autoPlay={autoPlay}
        loop={loop}
        className={mediaClasses}
        {...props}
      >
        {children}
      </audio>
    );
  }

  if (tag === 'iframe') {
    return (
      <iframe
        src={src}
        className={mediaClasses}
        width={style?.width}
        height={style?.height}
        frameBorder='0'
        allowFullScreen
        {...props}
      >
        {children}
      </iframe>
    );
  }

  if (tag === 'svg') {
    return (
      <svg
        className={mediaClasses}
        width={style?.width}
        height={style?.height}
        {...props}
      >
        {children}
      </svg>
    );
  }

  return (
    <Component
      src={src}
      className={mediaClasses}
      width={style?.width}
      height={style?.height}
      {...props}
    >
      {children}
    </Component>
  );
};

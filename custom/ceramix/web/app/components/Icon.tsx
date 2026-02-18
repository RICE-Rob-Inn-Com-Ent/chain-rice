'use client';

import { memo } from 'react';

interface IconProps {
  icon: string;
  className?: string;
  width?: string | number;
  height?: string | number;
  style?: React.CSSProperties;
}

/**
 * Icon component with Material Icons support
 * Maps icon names to SVG paths
 */
const Icon = memo(function Icon({
  icon,
  className = '',
  width = '1.5rem',
  height = '1.5rem',
  style,
}: IconProps) {
  // Icon mappings - Material Icons
  const iconPaths: Record<string, string> = {
    dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
    people: 'M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z',
    payments: 'M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 14H4v-6h16v6zm0-10H4V6h16v2z',
    event: 'M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V10h14v10zm0-12H5V6h14v2z',
    calendar_month: 'M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V10h14v10zm0-12H5V6h14v2z',
    receipt: 'M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 14H7v-2h2v2zm0-4H7V8h2v2zm4 4h-2v-2h2v2zm0-4h-2V8h2v2zm4 4h-2v-2h2v2zm0-4h-2V8h2v2z',
    logout: 'M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.59L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z',
    shield: 'M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z',
    account_balance: 'M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z',
    account_balance_wallet: 'M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 12H4v-6h16v6zm0-8H4V6h16v2zm-1 3h-2v2h2v-2z',
    wallet: 'M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 12H4v-6h16v6zm0-8H4V6h16v2zm-1 3h-2v2h2v-2z',
    medical_mask: 'M19.5 6c-1.31 0-2.37 1.01-2.48 2.3L15 10h-2V8.5c0-.83-.67-1.5-1.5-1.5h-3c-.83 0-1.5.67-1.5 1.5V10H5c-.55 0-1 .45-1 1v8c0 .55.45 1 1 1h14c.55 0 1-.45 1-1v-8c0-.55-.45-1-1-1h-1.02l-2.02-1.7c-.11-1.29-1.17-2.3-2.48-2.3zM12 14c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm6-6H6v6h12V8z',
    edit_location: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5zm6.5.5h-2v2h-1v-2h-2v-1h2v-2h1v2h2v1z',
    psychology: 'M12 2C6.48 2 2 6.48 2 12c0 1.54.36 2.98.97 4.29L1 23l6.71-1.97c1.31.61 2.75.97 4.29.97 5.52 0 10-4.48 10-10S17.52 2 12 2zm1.5 12h-3v-3h3v3zm0-5.5h-3V6h3v2.5z',
    location_on: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
    add_location: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm3 6h-2v2h-2v-2H9v-2h2V8h2v2h2v2z',
    add_location_alt_rounded: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm4 6h-2v2h-2v-2H8v-2h2V8h2v2h2v2z',
    location_on_rounded: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
    money_range_rounded: 'M7 15h2c0 1.08 1.37 2 3 2s3-.92 3-2c0-1.1-1.04-1.5-3.24-2.03C9.64 12.33 7 11.66 7 9c0-1.93 1.57-3.5 3.5-3.5.7 0 1.36.19 1.93.5.18.1.39.15.57.15.55 0 1-.45 1-1 0-.26-.11-.52-.29-.71-.19-.2-.45-.29-.71-.29-.55 0-1 .45-1 1H9c0-1.08 1.37-2 3-2s3 .92 3 2c0 1.1-1.04 1.5-3.24 2.03C10.36 11.67 13 12.34 13 15c0 1.93-1.57 3.5-3.5 3.5-.7 0-1.36-.19-1.93-.5-.18-.1-.39-.15-.57-.15-.55 0-1 .45-1 1 0 .26.11.52.29.71.19.2.45.29.71.29.55 0 1-.45 1-1h2z',
    settings: 'M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94L14.4 2.81c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z',
    close: 'M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z',
    filter_alt: 'M4.25 5.61C6.27 8.2 10 13 10 13v6c0 .55.45 1 1 1h2c.55 0 1-.45 1-1v-6s3.73-4.8 5.75-7.39c.51-.66.04-1.61-.79-1.61H5.04c-.83 0-1.3.95-.79 1.61z',
    filter_list: 'M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z',
  };

  const path = iconPaths[icon] || iconPaths.dashboard;

  return (
    <svg
      className={className}
      width={width}
      height={height}
      style={style}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-label={icon}
    >
      <path
        d={path}
        fill="currentColor"
        stroke="none"
      />
    </svg>
  );
}, (prevProps, nextProps) => {
  return (
    prevProps.icon === nextProps.icon &&
    prevProps.className === nextProps.className &&
    prevProps.width === nextProps.width &&
    prevProps.height === nextProps.height &&
    JSON.stringify(prevProps.style) === JSON.stringify(nextProps.style)
  );
});

Icon.displayName = 'Icon';

export default Icon;


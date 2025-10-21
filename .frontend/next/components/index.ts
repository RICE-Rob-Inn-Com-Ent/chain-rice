/**
 * InfiniR Next.js Components Library
 * Comprehensive component exports for rice-mono projects
 */

// Navigation Components
export { TopBar } from './navigation/TopBar';
export { Sidebar } from './navigation/Sidebar';

// Layout Components
export { DashboardLayout } from './layouts/DashboardLayout';
export { AppShell } from './layouts/AppShell';

// UI Components
export { Button } from './ui/Button';
export { IconButton } from './ui/IconButton';
export { Card } from './ui/Card';
export { Badge } from './ui/Badge';
export { Table } from './ui/Table';

// Dashboard Components
export { StatCard } from './dashboard/StatCard';

// Provider Components (do not re-export Next/React Query Providers to keep Vite apps light)
export { ConfigProvider, useUiConfig } from './config/ConfigProvider';

// Component Types
export type { TopBarProps } from './navigation/TopBar';
export type { SidebarProps } from './navigation/Sidebar';
export type { DashboardLayoutProps } from './layouts/DashboardLayout';
export type { ButtonProps } from './ui/Button';
export type { CardProps } from './ui/Card';
export type { BadgeProps } from './ui/Badge';
export type { StatCardProps } from './dashboard/StatCard';

// Re-export common React types
export type { ReactNode, ComponentProps } from 'react';
export type { Metadata, Viewport } from 'next';

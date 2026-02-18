'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import Icon from './Icon';

interface NavigationLinkProps {
  href: string;
  icon: string;
  label: string;
}

/**
 * NavigationLink component with active state highlighting
 */
export default function NavigationLink({ href, icon, label }: NavigationLinkProps) {
  const pathname = usePathname();
  const isActive = pathname === href || pathname?.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      prefetch={false}
      className={`flex items-center gap-3 rounded-lg px-4 py-3 transition ${
        isActive
          ? 'bg-white/10 text-ivory-100'
          : 'text-ivory-100/70 hover:bg-white/5 hover:text-ivory-100'
      }`}
    >
      <Icon icon={icon} className="text-[1.5rem]" />
      <span>{label}</span>
    </Link>
  );
}


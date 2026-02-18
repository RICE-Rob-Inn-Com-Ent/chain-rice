'use client'

import { Icon } from '@iconify/react'

export default function FixedHeart() {
  return (
    <div className="fixed left-0 top-1/2 -translate-y-1/2 -translate-x-1/4 z-[0] hidden lg:block pointer-events-none">
      <div className="relative inline-flex items-center justify-center">
        <Icon
          icon="material-symbols:favorite"
          className="w-[614px] h-[614px] text-[#F97316] opacity-15 rounded"
          style={{ fill: '#F97316' }}
        />
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-1">
          <span className="text-4xl font-extrabold uppercase tracking-widest text-black opacity-15 drop-shadow-lg">
            Kupujesz
          </span>
          <span className="text-4xl font-extrabold uppercase tracking-widest text-black opacity-15 drop-shadow-lg">
            Pomagasz
          </span>
        </div>
      </div>
    </div>
  )
}


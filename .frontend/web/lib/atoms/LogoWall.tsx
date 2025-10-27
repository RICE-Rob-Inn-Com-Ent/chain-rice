import React from 'react';
import Image from 'next/image';

const logos = [
  { src: '/logos/acme.svg', alt: 'Acme' },
  { src: '/logos/globex.svg', alt: 'Globex' },
  { src: '/logos/initech.svg', alt: 'Initech' },
  { src: '/logos/umbrella.svg', alt: 'Umbrella' },
  { src: '/logos/stark.svg', alt: 'Stark' },
  { src: '/logos/wayne.svg', alt: 'Wayne' },
];

export default function LogoWall() {
  return (
    <div className="grid grid-cols-2 items-center justify-items-center gap-8 opacity-80 md:grid-cols-6">
      {logos.map((l) => (
        <div key={l.alt} className="grayscale transition hover:grayscale-0">
          <Image src={l.src} alt={l.alt} width={120} height={32} />
        </div>
      ))}
    </div>
  );
}

export interface Product {
  id: string
  name: string
  price: number
  category: 'COFFEE' | 'TEA' | 'ILLUSTRATION'
  images: string[]
  featured?: boolean
  description?: string
  details?: {
    currentBeans?: string
    origin?: string
    roastProfile?: string
    processing?: string
    region?: string
    flavorProfile?: string
    variety?: string
    weight?: string
    composition?: string
    idealFor?: string
  }
}

export const allProducts: Product[] = [
  // KAWY
  {
    id: '1',
    name: 'Brazil Alta Mogiana',
    price: 49.50,
    category: 'COFFEE',
    images: ['/placeholder-coffee1.svg'],
    featured: true,
    description: '100% arabica, Speciality, Średnio palona. Profil smakowy: orzechy, czekolada, migdały. Idealna pod: ekspres ciśnieniowy, french press, kawiarka, tradycyjna metoda (zalewajka).',
    details: {
      currentBeans: 'Brazil Monte Carmelo',
      origin: 'Brazylia',
      roastProfile: 'Espresso (średni)',
      processing: 'Natural',
      region: 'Cajuru (Alta Mogiana)',
      flavorProfile: 'Orzechy, czekolada, migdały',
      variety: 'Catuaí',
      weight: '250g (ziarnista)',
      composition: '100% arabica, Speciality',
      idealFor: 'ekspres ciśnieniowy, french press, kawiarka, tradycyjna metoda (zalewajka)'
    }
  },
  {
    id: '2',
    name: 'Teppi Espresso Blend',
    price: 54.00,
    category: 'COFFEE',
    images: ['/placeholder-coffee2.svg'],
    featured: false,
    description: '100% arabica, Speciality, Średnio palona. Profil smakowy: orzechy, jaśmin. Idealna pod: ekspres ciśnieniowy, french press, kawiarka, tradycyjna metoda (zalewajka).',
    details: {
      roastProfile: 'Espresso (średni)',
      flavorProfile: 'Orzechy, jaśmin',
      composition: '100% arabica, Speciality (Brasil Mogiana 70%, Ethiopia Daye Bensa 30%)',
      weight: '250g (ziarnista)',
      idealFor: 'ekspres ciśnieniowy, french press, kawiarka, tradycyjna metoda (zalewajka)'
    }
  },
  // ŚWIĄTECZNE HERBATY
  {
    id: '4',
    name: 'Grzaniec Galicyjski',
    price: 24.99,
    category: 'TEA',
    images: ['/placeholder-tea1.svg'],
    featured: true
  },
  {
    id: '5',
    name: 'Świąteczna',
    price: 22.99,
    category: 'TEA',
    images: ['/placeholder-tea2.svg'],
    featured: false
  },
  {
    id: '6',
    name: 'Zimowa Opowieść',
    price: 26.99,
    category: 'TEA',
    images: ['/placeholder-tea3.svg'],
    featured: false
  },
  {
    id: '10',
    name: 'Wigilijna Noc',
    price: 28.99,
    category: 'TEA',
    images: ['/placeholder-tea4.svg'],
    featured: true
  },
  // CZARNE HERBATY po 100g
  {
    id: '11',
    name: 'Iberyjski Sen (100g)',
    price: 19.99,
    category: 'TEA',
    images: ['/placeholder-tea5.svg'],
    featured: false
  },
  {
    id: '12',
    name: 'Gruzińska (100g)',
    price: 21.99,
    category: 'TEA',
    images: ['/placeholder-tea6.svg'],
    featured: false
  },
  // ZIELONE HERBATY po 100g
  {
    id: '13',
    name: 'Chwila Relaksu (100g)',
    price: 23.99,
    category: 'TEA',
    images: ['/placeholder-tea7.svg'],
    featured: false
  },
  {
    id: '14',
    name: 'Cytrynowa Sencha (100g)',
    price: 25.99,
    category: 'TEA',
    images: ['/placeholder-tea8.svg'],
    featured: false
  },
  // OWOCOWE HERBATY po 100g
  {
    id: '15',
    name: 'Skarby Sadu (100g)',
    price: 20.99,
    category: 'TEA',
    images: ['/placeholder-tea9.svg'],
    featured: false
  },
  {
    id: '16',
    name: 'Owocowa Ekspresja (100g)',
    price: 22.99,
    category: 'TEA',
    images: ['/placeholder-tea10.svg'],
    featured: false
  },
  // BIAŁE HERBATY po 50g
  {
    id: '17',
    name: 'Biała Róża (50g)',
    price: 35.99,
    category: 'TEA',
    images: ['/placeholder-tea11.svg'],
    featured: true
  },
  {
    id: '18',
    name: 'Słodkie Tropiki (50g)',
    price: 37.99,
    category: 'TEA',
    images: ['/placeholder-tea12.svg'],
    featured: false
  },
  // ILUSTRACJE
  {
    id: '7',
    name: 'Kot na Drzewie - Ilustracja A4',
    price: 29.99,
    category: 'ILLUSTRATION',
    images: ['/placeholder-illustration1.svg'],
    featured: true
  },
  {
    id: '8',
    name: 'Śpiący Kotek - Ilustracja A3',
    price: 39.99,
    category: 'ILLUSTRATION',
    images: ['/placeholder-illustration2.svg'],
    featured: false
  },
  {
    id: '9',
    name: 'Rodzina Kotów - Ilustracja A2',
    price: 49.99,
    category: 'ILLUSTRATION',
    images: ['/placeholder-illustration3.svg'],
    featured: false
  }
]

export function getProductById(id: string): Product | undefined {
  return allProducts.find(product => product.id === id)
}

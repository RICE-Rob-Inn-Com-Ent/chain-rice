import React from 'react';
import * as Lib from '../lib';

type AnyComponent = React.ComponentType<any>;

// Demo props per component name (łatwo rozszerzysz w przyszłości)
const demoProps: Record<string, Record<string, any>> = {
  Button: { children: 'Click me', variant: 'primary' },
  Card: { title: 'Example Card', children: 'This is a card body.' },
};

function isRenderableComponent(value: unknown): value is AnyComponent {
  // Funkcyjny lub klasowy komponent React
  return typeof value === 'function' || (typeof value === 'object' && value !== null && '$$typeof' in (value as any));
}

export const ComponentGallery: React.FC = () => {
  const entries = Object.entries(Lib).filter(([name, exp]) => {
    // Filtruj tylko eksportowane komponenty, pomijaj typy/stałe
    return /^[A-Z]/.test(name) && isRenderableComponent(exp);
  }) as Array<[string, AnyComponent]>;

  return (
    <div className="space-y-8">
      <header>
        <h1 className="text-3xl font-bold">Components Lab</h1>
        <p className="text-gray-600">Podgląd wszystkich eksportów z lib/</p>
      </header>
      {entries.length === 0 ? (
        <p className="text-sm text-gray-500">Brak komponentów do wyświetlenia.</p>
      ) : (
        <div className="grid gap-6 md:grid-cols-2">
          {entries.map(([name, Comp]) => {
            const props = demoProps[name] ?? { children: `${name} example` };
            let rendered: React.ReactNode;
            try {
              rendered = <Comp {...props} />;
            } catch (e) {
              rendered = <div className="text-red-600 text-sm">Błąd renderowania: {(e as Error).message}</div>;
            }
            return (
              <section key={name} className="border rounded-md p-4 bg-white">
                <h2 className="font-semibold mb-2">{name}</h2>
                <div className="p-3 border rounded-md">{rendered}</div>
              </section>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default ComponentGallery;

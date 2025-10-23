import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';
import { ComponentGallery } from './ComponentGallery';

function App() {
  return (
    <main className="p-8">
      <ComponentGallery />
    </main>
  );
}

const rootEl = document.getElementById('root')!;
createRoot(rootEl).render(<App />);

if (import.meta && (import.meta as any).hot) {
  (import.meta as any).hot.accept();
}

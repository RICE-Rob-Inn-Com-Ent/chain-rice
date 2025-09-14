## Octave/MATLAB – przykład obliczeń

**Uruchomienie**

- Prosty skrypt: `octave --quiet index.m`
- Pipeline z danymi: `octave --quiet main.m` (wczyta `data/data.mat` jeśli istnieje)

## Co zawiera przykład?

- `compute.m`: funkcja licząca średnią i dodająca 1.
- `main.m`: wczytuje dane (lub używa wektora 1:5), uruchamia `compute` i wypisuje wynik.
- `data/`: miejsce na próbki (`data.mat` z polem `x`).

Zobacz `ARCHITECTURE.md`, aby poznać strukturę i rozszerzenia.



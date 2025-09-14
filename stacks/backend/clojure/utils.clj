(ns utils)

(defn read-config
  "Czyta proste EDN z pliku i zwraca mapę."
  [path]
  (-> path slurp read-string))



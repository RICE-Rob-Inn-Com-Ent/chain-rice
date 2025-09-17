(ns myapp.core
  (:require [shared :as shared]
            [utils :as utils]))

(defn greet
  "Zwraca komunikat powitalny na podstawie mapy opcji.
  Przykład: (greet {:prefix "Czesc" :name "Ala"})"
  ([] (shared/greeting-message {}))
  ([opts] (shared/greeting-message opts)))

(defn read-config-and-greet
  "Wczytuje konfigurację z pliku EDN i buduje komunikat powitalny.
  Przykład: (read-config-and-greet "config.edn")"
  [path]
  (-> path
      utils/read-config
      :greeting
      shared/greeting-message))



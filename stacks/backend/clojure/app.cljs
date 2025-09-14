(ns app
  (:require [shared :as shared]))

(defn main []
  (js/console.log (shared/greeting-message {:prefix "Hello" :name "Browser"})))



(ns hello.core
  (:require [utils]
            [shared]))

(defn -main [& _]
  (let [cfg (utils/read-config "config.edn")
        msg (shared/greeting-message (get cfg :greeting))]
    (println msg)))



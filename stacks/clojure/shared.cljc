;; Współdzielony kod Clojure/ClojureScript
(ns shared)

(defn greeting-message
  [{:keys [prefix name] :or {prefix "Hello" name "World"}}]
  (str prefix ", " name "!"))



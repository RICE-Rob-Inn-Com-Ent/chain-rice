(defproject examples-clojure-hello "0.1.0-SNAPSHOT"
  :description "Minimalny projekt Clojure: Hello World"
  :url "https://example.local"
  :license {:name "MIT"}
  :dependencies [[org.clojure/clojure "1.11.3"]]
  :main hello.core
  :profiles {:dev {:dependencies [[org.clojure/test.check "1.1.1"]]}})



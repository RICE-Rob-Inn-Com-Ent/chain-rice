(ns myapp.core-test
  (:require [clojure.test :refer [deftest is testing]]
            [shared :as shared]))

(deftest greeting-message-test
  (testing "default greeting"
    (is (= "Hello, World!" (shared/greeting-message {}))))
  (testing "custom greeting"
    (is (= "Czesc, Ala!" (shared/greeting-message {:prefix "Czesc" :name "Ala"})))) )



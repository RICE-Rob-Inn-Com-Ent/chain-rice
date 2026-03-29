module Main (main) where

import Laws (prop_decimalAddAssoc, prop_decimalMulDistrib)
import Test.Hspec
import Test.QuickCheck
import Verify (prop_moneySameCurrencyAdd)

-- [ ] hspec full suite; golden tests calc/test/golden/; fuzz RICE_CALC_PERF_MS

main :: IO ()
main = hspec $ do
  describe "Laws" $ do
    it "decimal addition is associative" $
      property prop_decimalAddAssoc
    it "multiplication distributes over addition" $
      property prop_decimalMulDistrib
  describe "Verify" $ do
    it "money add with matching currency codes" $
      property prop_moneySameCurrencyAdd

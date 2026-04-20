-- | Property tests for "Decimal" (numeric laws) and "Verify" (invariants, heavy fuzz).
module FuzzSpec (fuzzSpec) where

import Test.Hspec
import Test.Hspec.QuickCheck (modifyMaxSuccess)
import Test.QuickCheck
import Verify (
  prop_basisPointsFeeParses,
  prop_decimalAddAssoc,
  prop_decimalMulDistrib,
  prop_moneySameCurrencyAdd,
 )

-- | @maxQc@ from @RICE_CALC_QC_CASES@ (or default) — passed from "Main".
fuzzSpec :: Int -> Spec
fuzzSpec maxQc = do
  describe "Decimal (laws via RiceDecimal / Verify props)" $ do
    it "addition is associative" $
      modifyMaxSuccess (const maxQc) (property prop_decimalAddAssoc)
    it "multiplication distributes over addition" $
      modifyMaxSuccess (const maxQc) (property prop_decimalMulDistrib)

  describe "Verify (invariants)" $
    it "money add with matching currency codes" $
      modifyMaxSuccess (const maxQc) (property prop_moneySameCurrencyAdd)

  describe "Verify (heavy QuickCheck)" $
    it "basis point fee output parses as Decimal (10_000 cases)" $
      modifyMaxSuccess (const 10_000) (property prop_basisPointsFeeParses)

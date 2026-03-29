{-# OPTIONS_GHC -Wno-orphans #-}

-- | Domain-specific QuickCheck properties (money invariants, future ledger checks).
module Verify (
  prop_moneySameCurrencyAdd,
) where

import qualified Data.Text as T
import Laws ()
import Test.QuickCheck
import Decimal (RiceDecimal, plus)
import Money (Money (..), addMoney)

-- [ ] verify entry points for Rust FFI; RICE_* validators; VerifyResult proofs

instance Arbitrary Money where
  arbitrary = do
    code <- elements ["USD", "EUR", "PLN", "GBP"]
    Money (T.pack code) <$> arbitrary

prop_moneySameCurrencyAdd :: String -> RiceDecimal -> RiceDecimal -> Property
prop_moneySameCurrencyAdd cur a b =
  let c = T.pack cur
   in addMoney (Money c a) (Money c b) === Right (Money c (a `plus` b))

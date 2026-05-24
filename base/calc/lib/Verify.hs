{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE OverloadedStrings #-}

-- | QuickCheck laws and financial invariants (former Laws.hs + Verify.hs).
module Verify (
  prop_decimalAddAssoc,
  prop_decimalMulDistrib,
  prop_basisPointsFeeParses,
  prop_moneySameCurrencyAdd,
) where

import Data.Decimal (Decimal (..))
import Data.Word (Word8)
import qualified Data.Text as T
import Test.QuickCheck
import Text.Read (readMaybe)
import Wire (BasisPointsResponse (..), basisPointsFee)
import Decimal (Numeric, plus, times)
import Finance (Money (..), addMoney)

-- [ ] QuickCheck law generators; accounting identities; maxSuccess from CLERK_CALC_QC_CASES
-- [ ] verify entry points for Rust FFI; CLERK_* validators; VerifyResult proofs

instance Arbitrary Decimal where
  arbitrary = do
    p <- fromIntegral <$> choose (0 :: Int, 24 :: Int)
    m <- arbitrary
    pure (Decimal (p :: Word8) m)

instance Arbitrary Money where
  arbitrary = do
    code <- elements ["USD", "EUR", "PLN", "GBP"]
    Money (T.pack code) <$> arbitrary

prop_decimalAddAssoc :: Numeric -> Numeric -> Numeric -> Property
prop_decimalAddAssoc a b c =
  (a `plus` b) `plus` c === a `plus` (b `plus` c)

prop_decimalMulDistrib :: Numeric -> Numeric -> Numeric -> Property
prop_decimalMulDistrib a b c =
  (a `plus` b) `times` c === (a `times` c) `plus` (b `times` c)

-- | Basis-point fee output is always a parseable @Data.Decimal@ (kernel stays internally consistent).
prop_basisPointsFeeParses :: NonNegative Integer -> Property
prop_basisPointsFeeParses (NonNegative p) =
  forAll (choose (0, 1_000_000)) $ \bps ->
    case basisPointsFee (T.pack (show p)) bps of
      Left err -> counterexample (T.unpack err) False
      Right (BasisPointsResponse fee _ _) ->
        case readMaybe (T.unpack fee) :: Maybe Decimal of
          Nothing -> counterexample ("fee not a Decimal: " ++ T.unpack fee) False
          Just _ -> property True

prop_moneySameCurrencyAdd :: String -> Numeric -> Numeric -> Property
prop_moneySameCurrencyAdd cur a b =
  let c = T.pack cur
   in addMoney (Money c a) (Money c b) === Right (Money c (a `plus` b))

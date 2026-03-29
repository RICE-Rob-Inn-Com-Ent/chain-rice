{-# OPTIONS_GHC -Wno-orphans #-}

-- | Mathematical laws expressed as QuickCheck properties (associativity, distributivity).
module Laws (
  prop_decimalAddAssoc,
  prop_decimalMulDistrib,
) where

import Data.Decimal (Decimal (..))
import Data.Word (Word8)
import Test.QuickCheck
import Decimal (RiceDecimal, plus, times)

-- [ ] QuickCheck law generators; accounting identities; maxSuccess from RICE_CALC_QC_CASES

instance Arbitrary Decimal where
  arbitrary = do
    p <- fromIntegral <$> choose (0 :: Int, 24 :: Int)
    m <- arbitrary
    pure (Decimal (p :: Word8) m)

prop_decimalAddAssoc :: RiceDecimal -> RiceDecimal -> RiceDecimal -> Property
prop_decimalAddAssoc a b c =
  (a `plus` b) `plus` c === a `plus` (b `plus` c)

prop_decimalMulDistrib :: RiceDecimal -> RiceDecimal -> RiceDecimal -> Property
prop_decimalMulDistrib a b c =
  (a `plus` b) `times` c === (a `times` c) `plus` (b `times` c)

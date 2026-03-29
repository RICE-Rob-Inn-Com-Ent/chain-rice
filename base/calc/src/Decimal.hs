-- | Fixed-point decimal layer: mantissa/exponent model via "Data.Decimal", no "Double" in the API surface.
module Decimal (
  RiceDecimal,
  plus,
  minus,
  times,
  divideExact,
  roundPlaces,
  fromScientific,
  toScientific,
  normalize,
  Decimal (..),
  DecimalRaw,
  allocate,
  divide,
  normalizeDecimal,
  realFracToDecimal,
  roundTo,
  decimalPlaces,
  decimalMantissa,
) where

import Data.Decimal
import Data.Scientific (Scientific)
import Data.Word (Word8)

-- [ ] Data.Decimal — https://hackage.haskell.org/package/Decimal — RiceDecimal wrapper; Num/Fractional
-- [ ] rounding modes from RICE_CALC_ROUNDING_MODE; precision from RICE_CALC_PRECISION; QuickCheck laws; no Double/Float in API

-- | Canonical fixed-point amount (mantissa + decimal places).
type RiceDecimal = Decimal

plus :: RiceDecimal -> RiceDecimal -> RiceDecimal
plus = (+)

minus :: RiceDecimal -> RiceDecimal -> RiceDecimal
minus = (-)

times :: RiceDecimal -> RiceDecimal -> RiceDecimal
times = (*)

-- | Splittable division that preserves the sum invariant (see "divide").
divideExact :: Integral i => RiceDecimal -> [i] -> [RiceDecimal]
divideExact = divide

roundPlaces :: Word8 -> RiceDecimal -> RiceDecimal
roundPlaces = roundTo

normalize :: RiceDecimal -> RiceDecimal
normalize = normalizeDecimal

fromScientific :: Scientific -> RiceDecimal
fromScientific = fromRational . toRational

toScientific :: RiceDecimal -> Scientific
toScientific = fromRational . toRational

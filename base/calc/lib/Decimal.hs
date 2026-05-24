-- | Fixed-point decimal layer: mantissa/exponent model via "Data.Decimal", no "Double" in the API surface.
module Decimal (
  Numeric,
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

-- [ ] Data.Decimal — https://hackage.haskell.org/package/Decimal — Numeric alias; Num/Fractional
-- [ ] rounding modes from CLERK_CALC_ROUNDING_MODE; precision from CLERK_CALC_PRECISION; QuickCheck laws; no Double/Float in API

-- | Canonical fixed-point amount (mantissa + decimal places).
type Numeric = Decimal

plus :: Numeric -> Numeric -> Numeric
plus = (+)

minus :: Numeric -> Numeric -> Numeric
minus = (-)

times :: Numeric -> Numeric -> Numeric
times = (*)

-- | Splittable division that preserves the sum invariant (see "divide").
divideExact :: Integral i => Numeric -> [i] -> [Numeric]
divideExact = divide

roundPlaces :: Word8 -> Numeric -> Numeric
roundPlaces = roundTo

normalize :: Numeric -> Numeric
normalize = normalizeDecimal

fromScientific :: Scientific -> Numeric
fromScientific = fromRational . toRational

toScientific :: Numeric -> Scientific
toScientific = fromRational . toRational

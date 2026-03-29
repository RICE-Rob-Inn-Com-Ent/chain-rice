-- | Interest and amortization using fixed-point "Decimal" only (rates as decimals, e.g. 0.05 = 5%).
module Interest (
  simpleInterest,
  compoundPeriods,
  monthlyPayment,
) where

import Decimal (RiceDecimal, plus, minus, times)

-- [ ] compound, amortization, APR/APY; compounding frequency from config; QuickCheck

-- | Simple interest: @principal * rate * time@ (time in consistent units with the rate period).
simpleInterest :: RiceDecimal -> RiceDecimal -> RiceDecimal -> RiceDecimal
simpleInterest principal rate time = principal `times` rate `times` time

-- | Discrete compounding over @periods@ steps at @ratePerPeriod@ per step.
compoundPeriods :: RiceDecimal -> RiceDecimal -> Integer -> RiceDecimal
compoundPeriods principal ratePerPeriod periods =
  principal `times` ((1 `plus` ratePerPeriod) ^ periods)

-- | Level payment for @n@ periods at fixed rate @r@ per period (annuity formula).
monthlyPayment :: RiceDecimal -> RiceDecimal -> Int -> Maybe RiceDecimal
monthlyPayment principal periodicRate n
  | n <= 0 = Nothing
  | periodicRate == 0 = Just (principal / fromIntegral n)
  | otherwise = Just (principal `times` (numerator / denominator))
  where
    onePlusR = 1 `plus` periodicRate
    pow = onePlusR ^ n
    numerator = periodicRate `times` pow
    denominator = minus pow 1

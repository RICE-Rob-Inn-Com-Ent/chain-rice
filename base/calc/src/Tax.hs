-- | Tax helpers — brackets and VAT-style surcharges on fixed-point amounts (no "Double").
module Tax (
  vatOnNet,
  flatIncomeTax,
  progressiveMarginal,
) where

import Data.List (sortOn)
import Decimal (RiceDecimal, times, minus, plus)

-- [ ] progressive brackets; VAT inclusive/exclusive; withholding; rates from env/cue; QuickCheck

-- | Value-added style: tax = net * rate.
vatOnNet :: RiceDecimal -> RiceDecimal -> RiceDecimal
vatOnNet net rate = net `times` rate

-- | Single bracket: tax = max(0, income - allowance) * rate.
flatIncomeTax :: RiceDecimal -> RiceDecimal -> RiceDecimal -> RiceDecimal
flatIncomeTax allowance rate income =
  let taxable = if income `minus` allowance < 0 then 0 else income `minus` allowance
   in taxable `times` rate

-- | Piecewise-linear marginal schedule: @(upperBound, marginalRate)@ sorted ascending;
-- | last bound should exceed any realistic income (acts like top bracket).
progressiveMarginal :: [(RiceDecimal, RiceDecimal)] -> RiceDecimal -> RiceDecimal
progressiveMarginal raw income =
  snd $ foldl go (0, 0) (sortOn fst raw)
  where
    go (prevBound, acc) (lim, rate) =
      let slice = max (0 :: RiceDecimal) (min income lim `minus` prevBound)
          acc' = acc `plus` (slice `times` rate)
       in (lim, acc')

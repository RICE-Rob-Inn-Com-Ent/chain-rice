{-# LANGUAGE OverloadedStrings #-}

-- | Pure financial kernel: interest, tax, tagged money, basis-point fees, pruning helpers.
module Finance (
  -- * Money
  Money (..),
  zeroMoney,
  addMoney,
  scaleMoney,
  -- * Interest
  simpleInterest,
  compoundPeriods,
  monthlyPayment,
  -- * Tax
  vatOnNet,
  flatIncomeTax,
  progressiveMarginal,
  -- * Basis points (core fee math)
  BpsFeeOutcome (..),
  basisPointsFee,
  virtualJournalLine,
  -- * Pruning (list helpers)
  pruneEmptyTexts,
) where

import Data.Decimal (Decimal, normalizeDecimal)
import Data.List (sortOn)
import qualified Prelude as P
import Data.Text (Text)
import qualified Data.Text as T
import Text.Read (readMaybe)
import Decimal (Numeric, minus, plus, times)

-- ---------------------------------------------------------------------------
-- Money (from former Money.hs)
-- ---------------------------------------------------------------------------

-- | A currency-tagged fixed-point amount (ISO code as "Text" for now).
data Money = Money
  { moneyCurrency :: !Text
  , moneyAmount :: !Numeric
  }
  deriving (Eq, Show)

zeroMoney :: Text -> Money
zeroMoney c = Money c (0 :: Numeric)

addMoney :: Money -> Money -> Either Text Money
addMoney (Money c1 a1) (Money c2 a2)
  | c1 /= c2 = Left "currency mismatch"
  | otherwise = Right (Money c1 (plus a1 a2))

scaleMoney :: Numeric -> Money -> Money
scaleMoney k (Money c a) = Money c (times k a)

-- ---------------------------------------------------------------------------
-- Interest (from former Interest.hs)
-- ---------------------------------------------------------------------------

-- | Simple interest: @principal * rate * time@ (time in consistent units with the rate period).
simpleInterest :: Numeric -> Numeric -> Numeric -> Numeric
simpleInterest principal rate time = principal `times` rate `times` time

-- | Discrete compounding over @periods@ steps at @ratePerPeriod@ per step.
compoundPeriods :: Numeric -> Numeric -> Integer -> Numeric
compoundPeriods principal ratePerPeriod periods =
  principal `times` ((1 `plus` ratePerPeriod) ^ periods)

-- | Level payment for @n@ periods at fixed rate @r@ per period (annuity formula).
monthlyPayment :: Numeric -> Numeric -> Int -> Maybe Numeric
monthlyPayment principal periodicRate n
  | n <= 0 = Nothing
  | periodicRate == 0 = Just (principal / fromIntegral n)
  | otherwise = Just (principal `times` (numerator / denominator))
  where
    onePlusR = 1 `plus` periodicRate
    pow = onePlusR ^ n
    numerator = periodicRate `times` pow
    denominator = minus pow 1

-- ---------------------------------------------------------------------------
-- Tax (from former Tax.hs)
-- ---------------------------------------------------------------------------

-- | Value-added style: tax = net * rate.
vatOnNet :: Numeric -> Numeric -> Numeric
vatOnNet net rate = net `times` rate

-- | Single bracket: tax = max(0, income - allowance) * rate.
flatIncomeTax :: Numeric -> Numeric -> Numeric -> Numeric
flatIncomeTax allowance rate income =
  let taxable = if income `minus` allowance < 0 then 0 else income `minus` allowance
   in taxable `times` rate

-- | Piecewise-linear marginal schedule: @(upperBound, marginalRate)@ sorted ascending;
-- | last bound should exceed any realistic income (acts like top bracket).
progressiveMarginal :: [(Numeric, Numeric)] -> Numeric -> Numeric
progressiveMarginal raw income =
  snd $ foldl go (0, 0) (sortOn fst raw)
  where
    go (prevBound, acc) (lim, rate) =
      let slice = max (0 :: Numeric) (min income lim `minus` prevBound)
          acc' = acc `plus` (slice `times` rate)
       in (lim, acc')

-- ---------------------------------------------------------------------------
-- Basis-point fee (from former Logic.hs)
-- ---------------------------------------------------------------------------

-- | Result of basis-point fee computation (minor-unit decimal text + audit line + rounding label).
data BpsFeeOutcome = BpsFeeOutcome
  { bfoFee :: !Text
  , bfoJournal :: !Text
  , bfoRounding :: !Text
  }
  deriving stock (Show, Eq)

-- | One synthetic journal line (virtual posting) for hledger-style auditability.
virtualJournalLine :: Text -> Text -> Text -> Text
virtualJournalLine dateStr account feeStr =
  T.concat
    [ dateStr
    , " * rice-calc virtual fee\n  "
    , account
    , "  "
    , feeStr
    , "\n"
    ]

-- | @principal * bps / 10000@ using "Data.Decimal" 'Fractional' (truncate toward zero on finite scale).
basisPointsFee :: Text -> Integer -> Either Text BpsFeeOutcome
basisPointsFee principalTxt bps
  | bps < 0 || bps > 1_000_000 =
      Left "basis_points out of range [0, 1000000]"
  | otherwise = do
      principal <- case readMaybe (T.unpack principalTxt) of
        Nothing -> Left "principal_minor_units: invalid decimal"
        Just (p :: Decimal) -> Right (normalizeDecimal p)
      let fee =
            normalizeDecimal
              ( principal
                  P.* fromIntegral bps
                  P./ fromInteger 10000
              )
          feeTxt = T.pack (show fee)
          jline = virtualJournalLine "1970-01-01" "expenses:rice:fees" feeTxt
      Right $
        BpsFeeOutcome
          { bfoFee = feeTxt
          , bfoJournal = jline
          , bfoRounding = "truncate_toward_zero_fractional_divide"
          }

-- ---------------------------------------------------------------------------
-- Pruning (from former Pruning.hs) — list utilities at end of finance surface
-- ---------------------------------------------------------------------------

-- | Drop empty 'Text' entries.
pruneEmptyTexts :: [Text] -> [Text]
pruneEmptyTexts = filter (not . T.null)

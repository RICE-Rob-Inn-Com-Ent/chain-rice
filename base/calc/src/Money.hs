-- | Monetary amounts tagged with currency — arithmetic only on matching currencies, never "Double".
module Money (
  Money (..),
  zeroMoney,
  addMoney,
  scaleMoney,
) where

import Data.Text (Text)
import Decimal (RiceDecimal, plus, times)

-- [ ] iso-codes / currency validation; RICE_MONEY_LOCALE; QuickCheck invariants

-- | A currency-tagged fixed-point amount (ISO code as "Text" for now).
data Money = Money
  { moneyCurrency :: !Text
  , moneyAmount :: !RiceDecimal
  }
  deriving (Eq, Show)

zeroMoney :: Text -> Money
zeroMoney c = Money c (0 :: RiceDecimal)

addMoney :: Money -> Money -> Either Text Money
addMoney (Money c1 a1) (Money c2 a2)
  | c1 /= c2 = Left "currency mismatch"
  | otherwise = Right (Money c1 (plus a1 a2))

scaleMoney :: RiceDecimal -> Money -> Money
scaleMoney k (Money c a) = Money c (times k a)

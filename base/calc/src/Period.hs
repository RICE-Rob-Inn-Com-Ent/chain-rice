-- | Reporting periods and date spans — fiscal calendars defer to "hledger-lib" "Period" / "DateSpan".
module Period (
  Period (..),
  DateSpan (..),
) where

import Hledger.Data

-- [ ] RICE_FISCAL_YEAR_START; period split monthly/quarterly; overlap helpers

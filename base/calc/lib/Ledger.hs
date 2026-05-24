-- | Double-entry bookkeeping: hledger-lib types, journal metrics, fiscal periods.
module Ledger (
  -- * Re-exports from hledger (accounting surface)
  Account (..),
  AccountName,
  Posting (..),
  MixedAmount,
  Journal (..),
  Transaction (..),
  Ledger (..),
  Period (..),
  DateSpan (..),
  -- * Helpers
  journalTransactionCount,
  calcVirtualNote,
) where

import Hledger.Data

-- [ ] hledger-lib bridge; balanced ledger invariant; trial balance; QuickCheck
-- [ ] chart of accounts from CLERK_CHART_OF_ACCOUNTS; hierarchy; normal balance QuickCheck
-- [ ] CLERK_FISCAL_YEAR_START; period split monthly/quarterly; overlap helpers

-- | Number of transactions recorded in a journal (quick size metric).
journalTransactionCount :: Journal -> Int
journalTransactionCount = length . jtxns

-- | Marker comment for virtual postings produced by CALC (audit trail hook for indexers).
calcVirtualNote :: String -> String
calcVirtualNote detail = "; calc virtual: " ++ detail

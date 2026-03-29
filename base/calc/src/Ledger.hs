-- | Double-entry journal surface re-exported from "hledger-lib" — journals, transactions, postings.
module Ledger (
  Journal (..),
  Transaction (..),
  Posting (..),
  Ledger (..),
  journalTransactionCount,
) where

import Hledger.Data

-- [ ] hledger-lib bridge; balanced ledger invariant; trial balance; QuickCheck

-- | Number of transactions recorded in a journal (quick size metric).
journalTransactionCount :: Journal -> Int
journalTransactionCount = length . jtxns

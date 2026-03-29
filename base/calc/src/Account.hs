-- | Account trees, postings, and mixed commodity amounts — "hledger-lib" data model.
module Account (
  Account (..),
  AccountName,
  Posting (..),
  MixedAmount,
) where

import Hledger.Data

-- [ ] chart of accounts from RICE_CHART_OF_ACCOUNTS; hierarchy; normal balance QuickCheck

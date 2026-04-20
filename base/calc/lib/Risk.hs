-- | Financial / policy risk hooks for CALC (leverage, caps). Expand with real models.
module Risk (
  leverageRatio,
) where

import Data.Text (Text)

-- | Placeholder: ratio of exposure to collateral as a decimal string (e.g. @"1.0"@ = neutral).
leverageRatio :: Text -> Text -> Either Text Text
leverageRatio _exposure _collateral = Right "1.0"

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

-- | JSON / Aeson slow path for Rust and tooling. Hot path: "FFI" binary ABI + "Finance".
module Wire (
  BasisPointsRequest (..),
  BasisPointsResponse (..),
  WireJsonErr (..),
  basisPointsFee,
  basisPointsFeeJson,
  basisPointsFeeJsonUtf8,
  basisPointsFeeJsonBytes,
  basisPointsFeeJsonWire,
  outcomeToResponse,
) where

import Data.Aeson (
  FromJSON (..),
  ToJSON (..),
  eitherDecodeStrict,
  encode,
  object,
  withObject,
  (.=),
 )
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import GHC.Generics (Generic)
import Finance (BpsFeeOutcome (..), basisPointsFee as logicBasisPointsFee)

-- | Distinguish JSON parse failure from domain errors (for C return codes).
data WireJsonErr = WireJsonParse | WireJsonDomain !Text
  deriving stock (Show, Eq)

-- | Wire request: principal minor units as decimal ASCII string; basis points @0 .. 1_000_000@.
data BasisPointsRequest = BasisPointsRequest
  { bprPrincipalMinorUnits :: !Text
  , bprBasisPoints :: !Integer
  }
  deriving stock (Show, Generic)

instance FromJSON BasisPointsRequest where
  parseJSON = withObject "BasisPointsRequest" $ \o ->
    BasisPointsRequest <$> o .: "principal_minor_units" <*> o .: "basis_points"

-- | Wire response: fee string, journal fragment, rounding label.
data BasisPointsResponse = BasisPointsResponse
  { bpsFeeMinorUnits :: !Text
  , bpsJournalLine :: !Text
  , bpsRoundingMode :: !Text
  }
  deriving stock (Show, Generic)

instance ToJSON BasisPointsResponse where
  toJSON r =
    object
      [ "fee_minor_units" .= bpsFeeMinorUnits r
      , "journal_line" .= bpsJournalLine r
      , "rounding_mode" .= bpsRoundingMode r
      ]

outcomeToResponse :: BpsFeeOutcome -> BasisPointsResponse
outcomeToResponse o =
  BasisPointsResponse
    { bpsFeeMinorUnits = bfoFee o
    , bpsJournalLine = bfoJournal o
    , bpsRoundingMode = bfoRounding o
    }

-- | Same semantics as "Finance".basisPointsFee, wrapped in JSON wire types.
basisPointsFee :: Text -> Integer -> Either Text BasisPointsResponse
basisPointsFee p b = outcomeToResponse <$> logicBasisPointsFee p b

-- | Strict JSON in → JSON out (UTF-8 bytes).
basisPointsFeeJson :: LBS.ByteString -> Either Text LBS.ByteString
basisPointsFeeJson raw =
  case basisPointsFeeJsonWire (LBS.toStrict raw) of
    Left WireJsonParse -> Left (T.pack "json: parse error")
    Left (WireJsonDomain e) -> Left e
    Right b -> Right (LBS.fromStrict b)

-- | UTF-8 convenience (tests).
basisPointsFeeJsonUtf8 :: Text -> Either Text Text
basisPointsFeeJsonUtf8 t =
  case basisPointsFeeJson (LBS.fromStrict (TE.encodeUtf8 t)) of
    Left e -> Left e
    Right lbs -> Right (TE.decodeUtf8 (LBS.toStrict lbs))

-- | Strict bytes in → JSON response bytes out (legacy 'Either Text' — both errors flattened).
basisPointsFeeJsonBytes :: BS.ByteString -> Either Text BS.ByteString
basisPointsFeeJsonBytes bs =
  case basisPointsFeeJsonWire bs of
    Left WireJsonParse -> Left "json: parse error"
    Left (WireJsonDomain e) -> Left e
    Right out -> Right out

-- | Strict bytes in → JSON response bytes out with explicit error kind for FFI.
basisPointsFeeJsonWire :: BS.ByteString -> Either WireJsonErr BS.ByteString
basisPointsFeeJsonWire bs =
  case eitherDecodeStrict bs of
    Left _ -> Left WireJsonParse
    Right req ->
      case basisPointsFee (bprPrincipalMinorUnits req) (bprBasisPoints req) of
        Left e -> Left (WireJsonDomain e)
        Right resp -> Right (LBS.toStrict (encode resp))

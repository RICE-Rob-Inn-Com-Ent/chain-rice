{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Integration guard for "Finance", "Wire", and "FFI" (slow JSON + binary v1).
-- Full suite: "AuditSpec" (Ledger, Risk) + "FuzzSpec" (Decimal, Verify) + this module.
module Main (main) where

import AuditSpec (auditSpec)
import FuzzSpec (fuzzSpec)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as C8
import Data.Bits (shiftR)
import Data.Int (Int64)
import qualified Data.Text as T
import Data.Text (Text)
import Data.Word (Word32, Word8)
import FFI (decodeBpsBinaryRequestV1)
import qualified Finance
import qualified Wire
import System.Environment (lookupEnv)
import Test.Hspec

le32bytes :: Word32 -> [Word8]
le32bytes x =
  [ fromIntegral x
  , fromIntegral (x `shiftR` 8)
  , fromIntegral (x `shiftR` 16)
  , fromIntegral (x `shiftR` 24)
  ]

w32 :: Word32 -> BS.ByteString
w32 = BS.pack . le32bytes

i64le :: Int64 -> BS.ByteString
i64le v =
  BS.pack $
    le32bytes (fromIntegral v)
      ++ le32bytes (fromIntegral (v `shiftR` 32))

qcMaxSuccess :: IO Int
qcMaxSuccess =
  lookupEnv "CLERK_CALC_QC_CASES" >>= \case
    Just s
      | [(n, "")] <- reads s,
        n > 0 ->
          pure n
    _ -> pure 100

logicSpec :: Spec
logicSpec = do
  describe "Finance (core logic)" $ do
    it "calculates basis points correctly (10000 * 250 / 10000 = 250)" $
      case Finance.basisPointsFee "10000" 250 of
        Left e -> expectationFailure (T.unpack e)
        Right r -> Finance.bfoFee r `shouldBe` "250"
    it "prunes empty texts correctly" $
      Finance.pruneEmptyTexts [T.pack "", T.pack "a", T.pack ""] `shouldBe` [T.pack "a"]

  describe "Wire (JSON)" $
    it "basis points JSON round-trip contains correct fee" $ do
      let inp = "{\"principal_minor_units\":\"10000\",\"basis_points\":250}" :: Text
      case Wire.basisPointsFeeJsonUtf8 inp of
        Left e -> expectationFailure (T.unpack e)
        Right out -> out `shouldSatisfy` T.isInfixOf "\"fee_minor_units\":\"250\""

  describe "FFI (binary bridge)" $
    it "binary v1 correctly decodes principal and bps" $ do
      let req = mconcat [w32 1, w32 5, i64le 250, C8.pack "10000"]
      case decodeBpsBinaryRequestV1 req of
        Left e -> expectationFailure (T.unpack e)
        Right (p, b) -> do
          p `shouldBe` "10000"
          b `shouldBe` 250

main :: IO ()
main = do
  maxQc <- qcMaxSuccess
  hspec $ do
    auditSpec
    fuzzSpec maxQc
    logicSpec

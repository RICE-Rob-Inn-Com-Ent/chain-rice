{-# LANGUAGE OverloadedStrings #-}

-- | Ledger and risk surfaces: audit markers, policy hooks.
module AuditSpec (auditSpec) where

import Data.List (isInfixOf)
import qualified Data.Text as T
import Test.Hspec
import Ledger (riceCalcVirtualNote)
import Risk (leverageRatio)

auditSpec :: Spec
auditSpec = do
  describe "Ledger (audit)" $ do
    it "virtual note marker is stable for indexers and downstream parsers" $
      riceCalcVirtualNote "fee=0.25" `shouldBe` "; rice-calc virtual: fee=0.25"
    it "virtual note contains domain tag" $
      riceCalcVirtualNote "x" `shouldSatisfy` ("rice-calc virtual" `isInfixOf`)

  describe "Risk" $ do
    it "leverageRatio defaults to neutral 1.0" $
      leverageRatio "1" "1" `shouldBe` Right "1.0"
    it "leverageRatio accepts arbitrary exposure/collateral text" $
      leverageRatio (T.pack "x") (T.pack "y") `shouldBe` Right "1.0"

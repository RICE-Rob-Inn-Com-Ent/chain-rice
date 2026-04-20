{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-missing-export-lists #-}

-- | C ABI for Rust: RTS lifecycle, JSON slow path, binary v1 fast path ("rice_calc_*" symbols).
module FFI (
  riceBpsBinaryMagicV1,
  riceBpsBinaryMaxPrincipalLen,
  decodeBpsBinaryRequestV1,
  encodeBpsBinaryResponseV1,
  riceCalcBasisPointsFeeBinary,
) where

import Data.Bits (shiftL, shiftR, (.&.))
import qualified Data.ByteString as BS
import Data.ByteString.Unsafe (unsafeUseAsCStringLen)
import Data.Int (Int64)
import Foreign.C.Types (CChar (..), CInt (..), CSize (..))
import Foreign.Marshal.Alloc (free, mallocBytes)
import Foreign.Marshal.Utils (copyBytes)
import Foreign.Ptr (Ptr, castPtr, nullPtr)
import Foreign.Storable (poke)
import Data.Text (Text)
import qualified Data.Text.Encoding as TE
import Data.Word (Word32, Word64, Word8)
import Wire (WireJsonErr (..), basisPointsFeeJsonWire)
import Finance (BpsFeeOutcome (..), basisPointsFee)

-- | Request/response magic for v1 binary layout (LE @0x00000001@).
riceBpsBinaryMagicV1 :: Word32
riceBpsBinaryMagicV1 = 1

-- | Maximum UTF-8 length accepted for principal string in v1 binary requests.
riceBpsBinaryMaxPrincipalLen :: Int
riceBpsBinaryMaxPrincipalLen = 4096

le32 :: BS.ByteString -> Int -> Word32
le32 bs i =
  fromIntegral (BS.index bs i)
    .|. shiftL (fromIntegral (BS.index bs (i + 1))) 8
    .|. shiftL (fromIntegral (BS.index bs (i + 2))) 16
    .|. shiftL (fromIntegral (BS.index bs (i + 3))) 24

le64u :: BS.ByteString -> Int -> Word64
le64u bs i =
  fromIntegral (le32 bs i)
    .|. shiftL (fromIntegral (le32 bs (i + 4))) 32

le64 :: BS.ByteString -> Int -> Int64
le64 bs i = fromIntegral (le64u bs i)

word32le :: Word32 -> BS.ByteString
word32le w =
  BS.pack
    [ fromIntegral (w .&. 0xff)
    , fromIntegral ((w `shiftR` 8) .&. 0xff)
    , fromIntegral ((w `shiftR` 16) .&. 0xff)
    , fromIntegral ((w `shiftR` 24) .&. 0xff)
    ]

-- | Parse v1 binary request (same layout as Rust @util::calc@).
decodeBpsBinaryRequestV1 :: BS.ByteString -> Either Text (Text, Int64)
decodeBpsBinaryRequestV1 bs
  | BS.length bs < 16 =
      Left "binary bps v1: buffer too short (need >= 16)"
  | otherwise =
      let mag = le32 bs 0
          plen = fromIntegral (le32 bs 4) :: Int
          bps = le64 bs 8
       in if mag /= riceBpsBinaryMagicV1
            then Left "binary bps v1: bad magic"
            else
              if plen < 0 || plen > riceBpsBinaryMaxPrincipalLen
                then Left "binary bps v1: principal_len out of range"
                else
                  if BS.length bs < 16 + plen
                    then Left "binary bps v1: truncated principal"
                    else
                      let pbs = BS.take plen (BS.drop 16 bs)
                       in case TE.decodeUtf8' pbs of
                            Left _ -> Left "binary bps v1: invalid UTF-8 principal"
                            Right t -> Right (t, bps)

-- | Encode v1 binary response: magic, fee_len, fee UTF-8.
encodeBpsBinaryResponseV1 :: Text -> BS.ByteString
encodeBpsBinaryResponseV1 feeTxt =
  let feeBs = TE.encodeUtf8 feeTxt
      flen = fromIntegral (BS.length feeBs) :: Word32
   in word32le riceBpsBinaryMagicV1 <> word32le flen <> feeBs

-- | @0@ ok; @-1@ parse/UTF-8; @-2@ domain; @-3@ alloc/copy.
riceCalcBasisPointsFeeBinary ::
  Ptr Word8 ->
  CSize ->
  Ptr (Ptr Word8) ->
  Ptr CSize ->
  IO CInt
riceCalcBasisPointsFeeBinary inPtr inLen outPtrPtr outLenPtr = do
  let nIn = fromIntegral inLen
  inp <- BS.packCStringLen (castPtr inPtr :: Ptr Word8, nIn)
  case decodeBpsBinaryRequestV1 inp of
    Left _ ->
      pokeOutEmpty >> return (-1)
    Right (principal, bps64) ->
      case basisPointsFee principal (fromIntegral bps64) of
        Left _ ->
          pokeOutEmpty >> return (-2)
        Right outcome -> do
          let outBs = encodeBpsBinaryResponseV1 (bfoFee outcome)
              n = BS.length outBs
          p <- mallocBytes n
          copied <-
            unsafeUseAsCStringLen outBs $ \(src, n') ->
              if n' /= n
                then return False
                else do
                  copyBytes p (castPtr src :: Ptr Word8) n
                  return True
          if copied
            then do
              poke outPtrPtr p
              poke outLenPtr (fromIntegral n)
              return 0
            else do
              free p
              pokeOutEmpty >> return (-3)
  where
    pokeOutEmpty :: IO ()
    pokeOutEmpty = poke outPtrPtr nullPtr >> poke outLenPtr 0

-- ---------------------------------------------------------------------------
-- Foreign exports (RTS + C entrypoints; keep names stable for Rust dlopen)
-- ---------------------------------------------------------------------------

foreign import ccall "hs_init" hs_init :: Ptr CInt -> Ptr (Ptr CChar) -> IO ()

foreign import ccall "hs_exit" hs_exit :: IO ()

foreign export ccall rice_calc_init :: IO ()
rice_calc_init :: IO ()
rice_calc_init = hs_init nullPtr nullPtr

foreign export ccall rice_calc_shutdown :: IO ()
rice_calc_shutdown :: IO ()
rice_calc_shutdown = hs_exit

foreign export ccall rice_calc_free :: Ptr Word8 -> IO ()
rice_calc_free :: Ptr Word8 -> IO ()
rice_calc_free = free

foreign export ccall rice_calc_amount_from_basis_points_json ::
  Ptr Word8 ->
  CSize ->
  Ptr (Ptr Word8) ->
  Ptr CSize ->
  IO CInt
rice_calc_amount_from_basis_points_json inPtr inLen outPtrPtr outLenPtr = do
  let nIn = fromIntegral inLen
  bs <- BS.packCStringLen (castPtr inPtr :: Ptr Word8, nIn)
  case basisPointsFeeJsonWire bs of
    Left WireJsonParse ->
      pokeOutEmpty >> return (-1)
    Left (WireJsonDomain _) ->
      pokeOutEmpty >> return (-2)
    Right outBs ->
      copyOutBs outBs outPtrPtr outLenPtr
  where
    pokeOutEmpty :: IO ()
    pokeOutEmpty = poke outPtrPtr nullPtr >> poke outLenPtr 0
    copyOutBs :: BS.ByteString -> Ptr (Ptr Word8) -> Ptr CSize -> IO CInt
    copyOutBs outBs outPtrPtrPtr outLenPtrPtr = do
      let n = BS.length outBs
      p <- mallocBytes n
      copied <-
        unsafeUseAsCStringLen outBs $ \(src, n') ->
          if n' /= n
            then return False
            else do
              copyBytes p (castPtr src :: Ptr Word8) n
              return True
      if copied
        then do
          poke outPtrPtrPtr p
          poke outLenPtrPtr (fromIntegral n)
          return 0
        else do
          free p
          pokeOutEmpty
          return (-3)

foreign export ccall rice_calc_basis_points_fee_binary ::
  Ptr Word8 ->
  CSize ->
  Ptr (Ptr Word8) ->
  Ptr CSize ->
  IO CInt
rice_calc_basis_points_fee_binary = riceCalcBasisPointsFeeBinary

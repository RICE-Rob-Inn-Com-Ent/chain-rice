module Main where

import System.Environment (getArgs)
import Utils (greet)

main :: IO ()
main = do
  args <- getArgs
  let name = case args of
        (x:_) -> x
        _     -> "World"
  putStrLn (greet name)



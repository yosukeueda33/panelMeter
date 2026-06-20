{-# LANGUAGE DataKinds #-}

module Main where

import qualified Prelude as P 
import Language.Copilot hiding (alwaysBeen, since)
import Copilot.Language.Spec
import Copilot.Language.Stream
import Copilot.Compile.C99
import Lib (toggle, srsFF, oneShotRise)
import qualified Data.Bifunctor as BF

input0 = extern "input_0" Nothing :: Stream Bool
input1 = extern "input_1" Nothing :: Stream Bool
lightStates = extern "lightStates" Nothing :: Stream (Array 4 Word8)

blink :: Word16 -> Stream Bool
blink len = toggle $ clk1 (period len) (phase 0)

-- step is 101.7Hz
blinkSlow = blink 200
blinkFast = blink 10

selectedAndNoInput :: Int -> Stream Word8 -> Stream Word8 -> Stream Bool 
selectedAndNoInput input_i target now =
  let
    i = if input_i P.== 0 then input0 else input1
  in
    srsFF (oneShotRise (target == now)) i

calcLight :: Int -> Stream Bool
calcLight i =
  let
    -- l = fmap ((! (Const (fromIntegral i) :: Stream Word32)) . arrayElems) lightStates
    s = lightStates ! (Const (fromIntegral i) :: Stream Word32) :: Stream Word8
  in
    mux (s == 0) false
    $ mux (s == 1) true
    $ mux (s == 2) blinkSlow
    $ mux (s == 3) blinkFast
    $ mux (s == 4) true      -- removable
    $ mux (s == 5) blinkSlow -- removable
    $ mux (s == 6) blinkFast -- removeble
    -- Following mux is disabled because these consume ROM a lot!
    -- $ mux (s == 4) (blinkSlow && selectedAndNoInput 0 4 s)
    -- $ mux (s == 5) (blinkFast && selectedAndNoInput 0 5 s)
    -- $ mux (s == 6) (blinkSlow && selectedAndNoInput 1 6 s)
    -- $ mux (s == 7) (blinkFast && selectedAndNoInput 1 7 s)
    -- $ mux (s == 8) input0
    -- $ mux (s == 9) input1
    -- $ mux (s == 10) (toggle input0)
    -- $ mux (s == 11) (toggle input1)
    $ false

spec :: Spec
spec = do
  trigger "set_output" true $ map (arg . calcLight) [0..3]

main :: IO ()
main = do
  reify spec >>= compile "copilot_cords"

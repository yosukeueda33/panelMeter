{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Ivory.Language
import Ivory.Compile.C.CmdlineFrontend

printf :: Def ('[IString] ':-> Sint32)
printf = importProc "printf" "stdio.h"

txBuffer :: MemArea (Array 4 (Stored Uint8))
txBuffer = area "txBuffer" . Just . iarray $ replicate 4 izeroval

txBufferHead :: MemArea ('Stored Uint8)
txBufferHead = area "txBufferHead" $ Just (ival 0)

txBufferTail :: MemArea ('Stored Uint8)
txBufferTail = area "txBufferTail" $ Just (ival 0)


setMeter :: Def ('[Uint8, Uint8] ':-> ())
setMeter = importProc "set_meter" "infra.h"

-- setLight :: Def ('[Uint8, Uint8] ':-> ())
-- setLight = importProc "set_light" "infra.h"

hello :: Def ('[] ':-> ())
hello = proc "hello" $ body $ do
  call_ printf "Hello, world\n"
  retVoid

pushTxBuffer :: Def ('[Uint8] ':-> IBool)
pushTxBuffer = proc "pushTxBuffer" $ \x -> body $ do
  h <- deref (addrOf txBufferHead)
  t <- deref (addrOf txBufferTail)

  let next = (h + 1) .% 4

  ifte_ (next ==? t)
    ( do
        ret false
    )
    ( do
        store (addrOf txBuffer ! toIx h) x
        store (addrOf txBufferHead) next
        ret true
    )

popTxBuffer :: Def ('[Ref s ('Stored Uint8)] ':-> IBool)
popTxBuffer = proc "popTxBuffer" $ \out -> body $ do
  h <- deref (addrOf txBufferHead)
  t <- deref (addrOf txBufferTail)

  ifte_ (h ==? t)
    ( do
        ret false
    )
    ( do
        x <- deref (addrOf txBuffer ! toIx t)
        store out x
        store (addrOf txBufferTail) ((t + 1) .% 4)
        ret true
    )

state :: MemArea ('Stored Uint8)
state = area "state" $ Just (ival 0)

stateNone = 0 :: Uint8
stateGotHeadZero = 1 :: Uint8
stateGotIndex = 2 :: Uint8

index :: MemArea ('Stored Uint8)
index = area "index" $ Just (ival stateNone)

when_ c x = ifte_ c x $ return ()

parseByte :: Def ('[Uint8] ':-> Uint8)
parseByte = proc "parseByte" $ \x -> body $ do
  s <- deref $ addrOf state
  i <- deref $ addrOf index

  let
    u = iShiftR x 4 -- upper nibble
    l = x .& 0x0F -- lower nibble
    isHead = u ==? 0x8 
    setState y = store (addrOf state) y
    setIndex y = store (addrOf index) y

  ifte_ isHead
    (
      ifte_ (l ==? 0xF)
        (setState stateNone >> ret 0x8F)
        $ ifte_ (l ==? 0x0)
            ( setState stateGotHeadZero
              >> ret 0x8F
            )
            (ret $ x - 1)
    )
    $ do
        ifte_ (s ==? stateGotHeadZero)
          (setIndex x >> setState stateGotIndex)
          $ ifte_ (s ==? stateGotIndex)
              ( call_ setMeter i (x :: Uint8) >> setState stateNone)
              (return ()) -- stateNone or else
        ret x


helloModule :: Module
helloModule = package "HelloWorld" $ do
  incl printf
  incl hello

communicateModule :: Module
communicateModule = package "Communicate" $ do
  incl parseByte
  incl pushTxBuffer
  incl popTxBuffer
  defMemArea state
  defMemArea index
  defMemArea txBuffer
  defMemArea txBufferHead
  defMemArea txBufferTail
  incl setMeter
  -- incl setLight

main :: IO ()
main =
  runCompiler [helloModule, communicateModule] [] initialOpts
    { outDir = Just "generated"
    }
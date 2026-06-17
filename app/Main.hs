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


-- setMeter :: Def ('[Uint8, Uint8] ':-> ())
-- setMeter = importProc "set_meter" "infra.h"

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

helloModule :: Module
helloModule = package "HelloWorld" $ do
  incl printf
  incl hello

communicateModule :: Module
communicateModule = package "Communicate" $ do
  -- incl parseByte
  incl pushTxBuffer
  incl popTxBuffer
  defMemArea txBuffer
  defMemArea txBufferHead
  defMemArea txBufferTail
  -- incl setMeter
  -- incl setLight

main :: IO ()
main =
  runCompiler [helloModule, communicateModule] [] initialOpts
    { outDir = Just "generated"
    }
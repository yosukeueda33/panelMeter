{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Ivory.Language
import Ivory.Compile.C.CmdlineFrontend

printf :: Def ('[IString] ':-> Sint32)
printf = importProc "printf" "stdio.h"

hello :: Def ('[] ':-> ())
hello = proc "hello" $ body $ do
  call_ printf "Hello, world\n"
  retVoid

helloModule :: Module
helloModule = package "HelloWorld" $ do
  incl printf
  incl hello

main :: IO ()
main =
  runCompiler [helloModule] [] initialOpts
    { outDir = Just "generated"
    }
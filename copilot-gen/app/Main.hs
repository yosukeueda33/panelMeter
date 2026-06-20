module Main where

import qualified Prelude as P 
import Language.Copilot hiding (alwaysBeen, since)
import Copilot.Language.Spec
import Copilot.Language.Stream
import Copilot.Compile.C99
import Lib (oneShotRise, alwaysBeen', debounceRise, debounce, srsFF, once', weakPrevious, atLast, oneShotRise')
import qualified Data.Bifunctor as BF

spec :: Spec
spec = do
  trigger "set_led" true []

main :: IO ()
main = do
  reify spec >>= compile "copilot_cords"
